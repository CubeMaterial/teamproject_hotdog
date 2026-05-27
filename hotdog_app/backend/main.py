import sys
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

sys.path.append(str(Path(__file__).resolve().parent))
if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parent.parent))

from config import settings
from app.chatbot.router import router as chatbot_router
from user_common import UPLOADS_DIR, shutdown_user_api, startup_user_api
from routers.auth import router as admin_auth_router
from routers.board_posts import router as admin_board_posts_router
from routers.comments import router as admin_comments_router
from routers.dashboard import router as admin_dashboard_router
from routers.staffs import router as admin_staffs_router
from routers.inventory import router as admin_inventory_router
from routers.members import router as admin_members_router
from routers.user_auth import router as user_auth_router
from routers.user_products import router as user_products_router
from routers.user_purchases import router as user_purchases_router
from routers.user_reviews import router as user_reviews_router
from routers.user_staff import router as user_staff_router
from routers.user_accounts import router as user_accounts_router
from routers.purchase_order import router as admin_purchase_order_router
from routers.refunds import router as admin_refunds_router
from routers.sales_orders import router as admin_sales_orders_router
from routers.warehouse import router as admin_warehouse_router

app = FastAPI(title="Hotdog Unified API")

app.mount("/uploads", StaticFiles(directory=str(UPLOADS_DIR)), name="uploads")

app.include_router(admin_auth_router, prefix="/admin/auth", tags=["admin-auth"])
app.include_router(
    admin_dashboard_router,
    prefix="/admin/dashboard",
    tags=["admin-dashboard"],
)
app.include_router(admin_members_router, prefix="/admin/members", tags=["admin-members"])
app.include_router(admin_staffs_router, prefix="/admin/staffs", tags=["admin-staffs"])
app.include_router(
    admin_inventory_router,
    prefix="/admin/inventory",
    tags=["admin-inventory"],
)
app.include_router(
    admin_sales_orders_router,
    prefix="/admin/sales-orders",
    tags=["admin-sales-orders"],
)
app.include_router(
    admin_purchase_order_router,
    prefix="/admin/purchase-orders",
    tags=["admin-purchase-orders"],
)
app.include_router(admin_refunds_router, prefix="/admin/refunds", tags=["admin-refunds"])
app.include_router(
    admin_warehouse_router,
    prefix="/admin/warehouse",
    tags=["admin-warehouse"],
)
app.include_router(
    admin_board_posts_router,
    prefix="/admin/board-posts",
    tags=["admin-board-posts"],
)
app.include_router(admin_comments_router, prefix="/admin/comments", tags=["admin-comments"])

app.include_router(user_auth_router)
app.include_router(user_products_router)
app.include_router(user_reviews_router)
app.include_router(user_accounts_router)
app.include_router(user_purchases_router)
app.include_router(user_staff_router)
app.include_router(chatbot_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup() -> None:
    await startup_user_api()


@app.on_event("shutdown")
async def shutdown() -> None:
    await shutdown_user_api()


@app.get("/")
def read_root():
    return {"name": "Hotdog Unified API", "status": "ok"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.main:app", host=settings.FASTAPI_HOST, port=8000, reload=True)
