from __future__ import annotations

import math
import pickle
from functools import lru_cache
from pathlib import Path
from typing import Any

from database import get_connection


MODEL_PATH = Path(__file__).with_name("hotdog_demand_regression.h5")


def append_inventory_forecasts(
    inventory_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    if not inventory_rows:
        return inventory_rows

    rows = [dict(row) for row in inventory_rows]

    try:
        forecasts = build_category_forecasts()
    except Exception as error:
        print(f"Inventory forecast unavailable: {error}")
        return [_with_empty_forecast(row) for row in rows]

    return [_with_forecast(row, forecasts) for row in rows]


def build_category_forecasts() -> dict[int, dict[str, Any]]:
    runtime = _load_runtime()
    artifact = _load_model_artifact()
    model_df = _build_model_dataframe(runtime)

    if model_df.empty:
        return {}

    pd = runtime["pd"]
    np = runtime["np"]
    feature_cols = artifact["feature_cols"]
    latest_date = model_df["date"].max()
    latest_features = model_df[model_df["date"] == latest_date].copy()
    for col in feature_cols:
        if col not in latest_features.columns:
            latest_features[col] = np.nan

    forecasts: dict[int, dict[str, Any]] = {}
    for horizon in [7, 30]:
        model = artifact["models"][horizon]
        predictions = np.clip(model.predict(latest_features[feature_cols]), 0, None)

        if horizon == 7:
            latest_features["predictedDemand7d"] = predictions
            latest_features["predictedStockAfter7d"] = (
                latest_features["current_stock"].to_numpy()
                + latest_features["open_replenishment_qty"].fillna(0).to_numpy()
                - predictions
            ).clip(min=0)
            latest_features["stockRisk7d"] = [
                _risk_for_stock(stock, demand)
                for stock, demand in zip(
                    latest_features["predictedStockAfter7d"],
                    latest_features["predictedDemand7d"],
                )
            ]
        else:
            latest_features["predictedDemand30d"] = predictions
            latest_features["predictedStockAfter30d"] = (
                latest_features["current_stock"].to_numpy()
                + latest_features["open_replenishment_qty"].fillna(0).to_numpy()
                - predictions
            ).clip(min=0)
            latest_features["stockRisk30d"] = [
                _risk_for_stock(stock, demand)
                for stock, demand in zip(
                    latest_features["predictedStockAfter30d"],
                    latest_features["predictedDemand30d"],
                )
            ]

    forecast_date_7d = latest_date + pd.Timedelta(days=7)
    forecast_date_30d = latest_date + pd.Timedelta(days=30)

    for _, row in latest_features.iterrows():
        category_seq = _safe_int(row.get("product_sub_category_seq"))
        if category_seq is None:
            continue

        forecasts[category_seq] = {
            "forecastBaseDate": _date_text(latest_date),
            "forecastDate7d": _date_text(forecast_date_7d),
            "forecastDate30d": _date_text(forecast_date_30d),
            "forecastCategorySeq": category_seq,
            "forecastCategoryName": row.get("product_sub_category_name"),
            "predictedDemand7d": _round_or_none(row.get("predictedDemand7d")),
            "predictedStockAfter7d": _round_or_none(
                row.get("predictedStockAfter7d")
            ),
            "stockRisk7d": row.get("stockRisk7d"),
            "predictedDemand30d": _round_or_none(row.get("predictedDemand30d")),
            "predictedStockAfter30d": _round_or_none(
                row.get("predictedStockAfter30d")
            ),
            "stockRisk30d": row.get("stockRisk30d"),
        }

    return forecasts


@lru_cache(maxsize=1)
def _load_model_artifact() -> dict[str, Any]:
    runtime = _load_runtime()
    h5py = runtime["h5py"]

    with h5py.File(MODEL_PATH, "r") as h5_file:
        return pickle.loads(bytes(h5_file["model_pickle"][()]))


@lru_cache(maxsize=1)
def _load_runtime() -> dict[str, Any]:
    try:
        import h5py
        import numpy as np
        import pandas as pd
    except ImportError as error:
        raise RuntimeError(
            "ML 예측 패키지가 설치되어 있지 않습니다. "
            "backend/requirements.txt를 다시 설치해주세요."
        ) from error

    return {"h5py": h5py, "np": np, "pd": pd}


def _build_model_dataframe(runtime: dict[str, Any]):
    pd = runtime["pd"]

    with get_connection() as connection:
        buy_raw = _query_df(connection, _BUY_SQL)
        orders_raw = _query_df(connection, _ORDERS_SQL)
        receive_raw = _query_df(connection, _RECEIVE_SQL)
        product_raw = _query_df(connection, _PRODUCT_SQL)

    buy = buy_raw.copy()
    orders = orders_raw.copy()
    receive = receive_raw.copy()
    product = product_raw.copy()

    _ensure_columns(
        buy,
        [
            "buy_seq",
            "buy_date",
            "buy_qty",
            "buy_price",
            "product_seq",
            "user_seq",
            "event_seq",
            "current_stock",
            "product_price",
            "product_sub_category_seq",
            "product_sub_category_name",
        ],
    )
    _ensure_columns(
        orders,
        [
            "order_seq",
            "warehouse_seq",
            "maker_seq",
            "staff_seq",
            "product_seq",
            "order_date",
            "order_qty",
            "order_price",
            "order_done",
        ],
    )
    _ensure_columns(
        receive,
        [
            "receive_seq",
            "product_seq",
            "order_seq",
            "staff_seq",
            "maker_seq",
            "warehouse_seq",
            "receive_qty",
            "receive_date",
        ],
    )
    _ensure_columns(
        product,
        [
            "product_seq",
            "current_stock",
            "product_price",
            "product_sub_category_seq",
            "product_sub_category_name",
        ],
    )

    if product.empty:
        return pd.DataFrame()

    buy["buy_date"] = pd.to_datetime(buy["buy_date"], errors="coerce")
    buy["date"] = buy["buy_date"].dt.normalize()
    _to_numeric(
        buy,
        [
            "buy_seq",
            "buy_qty",
            "buy_price",
            "product_seq",
            "user_seq",
            "event_seq",
            "current_stock",
            "product_price",
            "product_sub_category_seq",
        ],
    )

    orders["order_date"] = pd.to_datetime(orders["order_date"], errors="coerce")
    orders["date"] = orders["order_date"].dt.normalize()
    _to_numeric(
        orders,
        [
            "order_seq",
            "warehouse_seq",
            "maker_seq",
            "staff_seq",
            "product_seq",
            "order_qty",
            "order_price",
            "order_done",
        ],
    )

    receive["receive_date"] = pd.to_datetime(
        receive["receive_date"],
        errors="coerce",
    )
    receive["date"] = receive["receive_date"].dt.normalize()
    _to_numeric(
        receive,
        [
            "receive_seq",
            "product_seq",
            "order_seq",
            "staff_seq",
            "maker_seq",
            "warehouse_seq",
            "receive_qty",
        ],
    )

    _to_numeric(
        product,
        [
            "product_seq",
            "current_stock",
            "product_price",
            "product_sub_category_seq",
        ],
    )

    product_lookup = product[
        [
            "product_seq",
            "product_sub_category_seq",
            "product_sub_category_name",
            "product_price",
            "current_stock",
        ]
    ].drop_duplicates("product_seq")
    orders = orders.merge(product_lookup, on="product_seq", how="left")
    receive = receive.merge(product_lookup, on="product_seq", how="left")

    order_receive = orders.merge(
        receive[["order_seq", "receive_date", "receive_qty"]],
        on="order_seq",
        how="left",
        suffixes=("_order", "_receive"),
    )
    order_receive["order_receive_lead_hours"] = (
        order_receive["receive_date"] - order_receive["order_date"]
    ).dt.total_seconds() / 3600

    return _make_model_df(pd, buy, orders, receive, order_receive, product)


def _make_model_df(pd, buy, orders, receive, order_receive, product):
    category_info = (
        product.groupby(
            ["product_sub_category_seq", "product_sub_category_name"],
            as_index=False,
        )
        .agg(
            current_stock=("current_stock", "sum"),
            product_count=("product_seq", "nunique"),
            avg_product_price=("product_price", "mean"),
            min_product_price=("product_price", "min"),
            max_product_price=("product_price", "max"),
        )
    )

    date_columns = [
        buy["date"].dropna(),
        orders["date"].dropna(),
        receive["date"].dropna(),
    ]
    non_empty_dates = [dates for dates in date_columns if not dates.empty]
    if non_empty_dates:
        start_date = min(dates.min() for dates in non_empty_dates)
        end_date = max(dates.max() for dates in non_empty_dates)
    else:
        end_date = pd.Timestamp.today().normalize()
        start_date = end_date

    all_dates = pd.date_range(start_date, end_date, freq="D")
    category_ids = category_info["product_sub_category_seq"].sort_values().unique()
    grid = pd.MultiIndex.from_product(
        [all_dates, category_ids],
        names=["date", "product_sub_category_seq"],
    ).to_frame(index=False)

    category_sales_daily = (
        buy.groupby(["date", "product_sub_category_seq"], as_index=False)
        .agg(
            daily_buy_qty=("buy_qty", "sum"),
            avg_buy_price=("buy_price", "mean"),
            buy_count=("buy_seq", "count"),
            unique_buy_users=("user_seq", "nunique"),
            sold_products=("product_seq", "nunique"),
            event_count=("event_seq", lambda values: values.notna().sum()),
        )
    )

    category_order_daily = (
        orders.groupby(["date", "product_sub_category_seq"], as_index=False)
        .agg(
            daily_order_qty=("order_qty", "sum"),
            avg_order_price=("order_price", "mean"),
            order_count=("order_seq", "count"),
            order_done_rate=("order_done", "mean"),
        )
    )

    category_receive_daily = (
        receive.groupby(["date", "product_sub_category_seq"], as_index=False)
        .agg(
            daily_receive_qty=("receive_qty", "sum"),
            receive_count=("receive_seq", "count"),
        )
    )

    category_lead = (
        order_receive.groupby("product_sub_category_seq", as_index=False)[
            "order_receive_lead_hours"
        ]
        .mean()
        .rename(
            columns={
                "order_receive_lead_hours": (
                    "category_order_receive_lead_mean_hours"
                )
            }
        )
    )

    model_df = (
        grid.merge(category_info, on="product_sub_category_seq", how="left")
        .merge(
            category_sales_daily,
            on=["date", "product_sub_category_seq"],
            how="left",
        )
        .merge(
            category_order_daily,
            on=["date", "product_sub_category_seq"],
            how="left",
        )
        .merge(
            category_receive_daily,
            on=["date", "product_sub_category_seq"],
            how="left",
        )
        .merge(category_lead, on="product_sub_category_seq", how="left")
        .sort_values(["product_sub_category_seq", "date"])
        .reset_index(drop=True)
    )

    zero_cols = [
        "daily_buy_qty",
        "buy_count",
        "unique_buy_users",
        "sold_products",
        "event_count",
        "daily_order_qty",
        "order_count",
        "daily_receive_qty",
        "receive_count",
    ]
    for col in zero_cols:
        model_df[col] = model_df[col].fillna(0)

    model_df["avg_buy_price"] = model_df["avg_buy_price"].fillna(
        model_df["avg_product_price"]
    )
    model_df["avg_order_price"] = model_df["avg_order_price"].fillna(
        model_df["avg_product_price"]
    )
    model_df["order_done_rate"] = model_df["order_done_rate"].fillna(0)

    model_df["year"] = model_df["date"].dt.year
    model_df["month"] = model_df["date"].dt.month
    model_df["day"] = model_df["date"].dt.day
    model_df["day_of_week"] = model_df["date"].dt.dayofweek
    model_df["day_of_year"] = model_df["date"].dt.dayofyear
    model_df["week_of_year"] = model_df["date"].dt.isocalendar().week.astype(int)
    model_df["is_weekend"] = model_df["day_of_week"].isin([5, 6]).astype(int)

    model_df["cum_order_qty"] = model_df.groupby("product_sub_category_seq")[
        "daily_order_qty"
    ].cumsum()
    model_df["cum_receive_qty"] = model_df.groupby("product_sub_category_seq")[
        "daily_receive_qty"
    ].cumsum()
    model_df["open_replenishment_qty"] = (
        model_df["cum_order_qty"] - model_df["cum_receive_qty"]
    ).clip(lower=0)
    model_df["cum_buy_qty_to_date"] = (
        model_df.groupby("product_sub_category_seq")["daily_buy_qty"].cumsum()
        - model_df["daily_buy_qty"]
    )

    for base_col in [
        "daily_buy_qty",
        "daily_order_qty",
        "daily_receive_qty",
        "open_replenishment_qty",
        "buy_count",
        "sold_products",
    ]:
        for lag in [1, 2, 3, 7, 14, 21, 28]:
            model_df[f"{base_col}_lag_{lag}"] = model_df.groupby(
                "product_sub_category_seq"
            )[base_col].shift(lag)
        for window in [3, 7, 14, 28, 60]:
            shifted = model_df.groupby("product_sub_category_seq")[base_col].shift(
                1
            )
            model_df[f"{base_col}_roll_mean_{window}"] = (
                shifted.groupby(model_df["product_sub_category_seq"])
                .rolling(window, min_periods=1)
                .mean()
                .reset_index(level=0, drop=True)
            )
            model_df[f"{base_col}_roll_sum_{window}"] = (
                shifted.groupby(model_df["product_sub_category_seq"])
                .rolling(window, min_periods=1)
                .sum()
                .reset_index(level=0, drop=True)
            )

    sold_flag = model_df["daily_buy_qty"].gt(0)
    model_df["last_sale_date"] = model_df["date"].where(sold_flag)
    model_df["last_sale_date"] = model_df.groupby("product_sub_category_seq")[
        "last_sale_date"
    ].ffill()
    model_df["days_since_last_sale"] = (
        model_df["date"] - model_df["last_sale_date"]
    ).dt.days
    model_df = model_df.drop(columns=["last_sale_date"])

    global_daily = (
        model_df.groupby("date", as_index=False)
        .agg(
            global_buy_qty=("daily_buy_qty", "sum"),
            global_order_qty=("daily_order_qty", "sum"),
            global_receive_qty=("daily_receive_qty", "sum"),
        )
        .sort_values("date")
    )
    for col in ["global_buy_qty", "global_order_qty", "global_receive_qty"]:
        for lag in [7, 14, 28]:
            global_daily[f"{col}_lag_{lag}"] = global_daily[col].shift(lag)
        global_daily[f"{col}_roll_mean_28"] = (
            global_daily[col].shift(1).rolling(28, min_periods=1).mean()
        )

    return model_df.merge(global_daily, on="date", how="left")


def _query_df(connection, sql: str):
    runtime = _load_runtime()
    pd = runtime["pd"]

    with connection.cursor() as cursor:
        cursor.execute(sql)
        return pd.DataFrame(cursor.fetchall())


def _to_numeric(df, cols: list[str]) -> None:
    runtime = _load_runtime()
    pd = runtime["pd"]

    for col in cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")


def _ensure_columns(df, cols: list[str]) -> None:
    for col in cols:
        if col not in df.columns:
            df[col] = None


def _with_forecast(
    row: dict[str, Any],
    forecasts: dict[int, dict[str, Any]],
) -> dict[str, Any]:
    category_seq = _safe_int(
        row.get("productSubCategorySeq")
        or row.get("product_sub_category_seq")
        or row.get("productCategorySeq")
        or row.get("product_category_seq")
    )
    forecast = forecasts.get(category_seq) if category_seq is not None else None

    if forecast is None:
        return _with_empty_forecast(row)

    row.update(forecast)
    return row


def _with_empty_forecast(row: dict[str, Any]) -> dict[str, Any]:
    row.update(
        {
            "forecastBaseDate": None,
            "forecastDate7d": None,
            "forecastDate30d": None,
            "forecastCategorySeq": None,
            "forecastCategoryName": None,
            "predictedDemand7d": None,
            "predictedStockAfter7d": None,
            "stockRisk7d": None,
            "predictedDemand30d": None,
            "predictedStockAfter30d": None,
            "stockRisk30d": None,
        }
    )
    return row


def _risk_for_stock(predicted_stock: Any, predicted_demand: Any) -> str:
    stock = _safe_float(predicted_stock)
    demand = _safe_float(predicted_demand) or 0

    if stock is None:
        return "UNKNOWN"
    if stock <= 5:
        return "HIGH"
    if stock <= max(10, demand):
        return "WATCH"
    return "OK"


def _safe_int(value: Any) -> int | None:
    try:
        if value is None:
            return None
        if isinstance(value, float) and math.isnan(value):
            return None
        return int(value)
    except (TypeError, ValueError):
        return None


def _safe_float(value: Any) -> float | None:
    try:
        if value is None:
            return None
        number = float(value)
        if math.isnan(number):
            return None
        return number
    except (TypeError, ValueError):
        return None


def _round_or_none(value: Any) -> float | None:
    number = _safe_float(value)
    if number is None:
        return None
    return round(number, 2)


def _date_text(value: Any) -> str | None:
    if value is None:
        return None
    if hasattr(value, "date"):
        return value.date().isoformat()
    return str(value)


_BUY_SQL = """
SELECT
    b.buy_seq,
    b.buy_date,
    b.buy_qty,
    b.buy_price,
    b.product_seq,
    b.user_seq,
    NULL AS event_seq,
    p.product_qty AS current_stock,
    p.product_price,
    sc.product_sub_category_seq,
    sc.product_sub_category_name
FROM buy b
JOIN product p
    ON b.product_seq = p.product_seq
LEFT JOIN (
    SELECT
        product_seq,
        MIN(product_sub_category_seq) AS product_sub_category_seq,
        GROUP_CONCAT(
            DISTINCT product_sub_category_name
            ORDER BY product_sub_category_seq
            SEPARATOR ', '
        ) AS product_sub_category_name
    FROM product_sub_category
    GROUP BY product_seq
) sc ON sc.product_seq = p.product_seq
WHERE b.buy_date IS NOT NULL
  AND b.buy_qty IS NOT NULL
  AND b.product_seq IS NOT NULL
  AND b.user_seq IS NOT NULL
ORDER BY b.buy_date, b.buy_seq
"""

_ORDERS_SQL = """
SELECT
    order_seq,
    warehouse_seq,
    maker_seq,
    staff_seq,
    product_seq,
    order_date,
    order_qty,
    order_price,
    order_done
FROM orders
WHERE order_date IS NOT NULL
  AND product_seq IS NOT NULL
ORDER BY order_date, order_seq
"""

_RECEIVE_SQL = """
SELECT
    receive_seq,
    product_seq,
    order_seq,
    staff_seq,
    maker_seq,
    warehouse_seq,
    receive_qty,
    receive_date
FROM receive
WHERE receive_date IS NOT NULL
  AND product_seq IS NOT NULL
ORDER BY receive_date, receive_seq
"""

_PRODUCT_SQL = """
SELECT
    p.product_seq,
    p.product_qty AS current_stock,
    p.product_price,
    sc.product_sub_category_seq,
    sc.product_sub_category_name
FROM product p
LEFT JOIN (
    SELECT
        product_seq,
        MIN(product_sub_category_seq) AS product_sub_category_seq,
        GROUP_CONCAT(
            DISTINCT product_sub_category_name
            ORDER BY product_sub_category_seq
            SEPARATOR ', '
        ) AS product_sub_category_name
    FROM product_sub_category
    GROUP BY product_seq
) sc ON sc.product_seq = p.product_seq
WHERE sc.product_sub_category_seq IS NOT NULL
"""
