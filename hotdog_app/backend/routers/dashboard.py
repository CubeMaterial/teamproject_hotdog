from datetime import date, timedelta

from fastapi import APIRouter

from database import fetch_query, fetch_single_value

router = APIRouter()


@router.get("/summary")
def get_dashboard_summary():
    today = date.today()
    month_start = today.replace(day=1)
    recent_sales_start = today - timedelta(days=6)

    today_sales = fetch_single_value(
        """
        SELECT COALESCE(SUM(buy_price), 0) AS total
        FROM buy
        WHERE DATE(buy_date) = %s
        """,
        (today,),
    )
    month_sales = fetch_single_value(
        """
        SELECT COALESCE(SUM(buy_price), 0) AS total
        FROM buy
        WHERE DATE(buy_date) >= %s
        """,
        (month_start,),
    )
    refund_count = fetch_single_value("SELECT COUNT(*) AS count FROM refund")
    today_post_count = fetch_single_value(
        """
        SELECT COUNT(*) AS count
        FROM warning
        WHERE DATE(warning_date) = %s
        """,
        (today,),
    )

    weekly_rows = fetch_query(
        """
        SELECT DATE(buy_date) AS sale_date, COALESCE(SUM(buy_price), 0) AS total
        FROM buy
        WHERE DATE(buy_date) >= %s AND DATE(buy_date) < %s
        GROUP BY DATE(buy_date)
        """,
        (recent_sales_start, today),
    )
    weekly_by_date = {
        row["sale_date"].isoformat(): int(row["total"] or 0) for row in weekly_rows
    }
    weekly_sales = [
        weekly_by_date.get((recent_sales_start + timedelta(days=index)).isoformat(), 0)
        for index in range(6)
    ]

    top_selling_products = fetch_query(
        """
        SELECT
            p.product_name AS name,
            COALESCE(SUM(b.buy_qty), 0) AS quantity,
            COALESCE(SUM(b.buy_price), 0) AS salesAmount
        FROM buy b
        JOIN product p ON p.product_seq = b.product_seq
        GROUP BY p.product_seq, p.product_name
        ORDER BY quantity DESC
        LIMIT 5
        """
    )

    if not top_selling_products:
        top_selling_products = fetch_query(
            """
            SELECT
                product_name AS name,
                COALESCE(product_qty, 0) AS quantity,
                COALESCE(product_price, 0) AS salesAmount
            FROM product
            ORDER BY product_seq DESC
            LIMIT 5
            """
        )

    return {
        "todaySales": int(today_sales or 0),
        "monthSales": int(month_sales or 0),
        "weeklySales": weekly_sales,
        "refundCount": int(refund_count or 0),
        "todayPostCount": int(today_post_count or 0),
        "topSellingProducts": top_selling_products,
    }
