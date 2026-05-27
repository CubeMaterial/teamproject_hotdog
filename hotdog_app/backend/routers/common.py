from fastapi import APIRouter, Query

from database import fetch_all, fetch_one_by_id


def create_list_router(table_name: str, id_column: str = "id") -> APIRouter:
    router = APIRouter()

    @router.get("/")
    def list_items(limit: int = Query(default=100, ge=1, le=500)):
        return fetch_all(table_name, limit=limit)

    @router.get("/{item_id}")
    def get_item(item_id: str):
        return fetch_one_by_id(table_name, id_column, item_id)

    return router
