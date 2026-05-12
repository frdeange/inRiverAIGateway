from copy import deepcopy

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

app = FastAPI(title="inRiver Credit Service", version="1.0.0")

INITIAL_TENANTS = {
    "tenant-adidas": {"name": "Adidas", "monthly_quota": 10000, "used": 0},
    "tenant-nike": {"name": "Nike", "monthly_quota": 500, "used": 450},
    "tenant-startup": {"name": "Startup X", "monthly_quota": 0, "used": 0},
}

tenants = deepcopy(INITIAL_TENANTS)


class ConsumeRequest(BaseModel):
    tenantId: str
    tokens: int = Field(..., gt=0)


def get_tenant(tenant_id: str) -> dict:
    tenant = tenants.get(tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail=f"Unknown tenant: {tenant_id}")
    return tenant


@app.get("/api/check")
def check_credits(tenantId: str):
    tenant = get_tenant(tenantId)
    remaining = max(tenant["monthly_quota"] - tenant["used"], 0)
    if remaining > 0:
        return {"allowed": True, "remaining": remaining}
    return JSONResponse(status_code=403, content={"allowed": False, "remaining": 0})


@app.post("/api/consume")
def consume_credits(payload: ConsumeRequest):
    tenant = get_tenant(payload.tenantId)
    remaining = max(tenant["monthly_quota"] - tenant["used"], 0)

    if payload.tokens > remaining:
        raise HTTPException(
            status_code=403,
            detail={"allowed": False, "remaining": remaining, "message": "Not enough credits"},
        )

    tenant["used"] += payload.tokens
    new_remaining = max(tenant["monthly_quota"] - tenant["used"], 0)
    return {
        "tenantId": payload.tenantId,
        "consumed": payload.tokens,
        "used": tenant["used"],
        "remaining": new_remaining,
        "allowed": new_remaining > 0,
    }


@app.get("/api/tenants")
def list_tenants():
    snapshot = {}
    for tenant_id, data in tenants.items():
        remaining = max(data["monthly_quota"] - data["used"], 0)
        snapshot[tenant_id] = {
            "name": data["name"],
            "monthly_quota": data["monthly_quota"],
            "used": data["used"],
            "remaining": remaining,
        }
    return snapshot


@app.get("/api/reset")
def reset_tenants():
    global tenants
    tenants = deepcopy(INITIAL_TENANTS)
    return {"status": "reset", "tenants": tenants}


@app.get("/health")
def health():
    return {"status": "ok"}
