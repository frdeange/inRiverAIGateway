import os
import sys
from datetime import datetime, timedelta, timezone

import jwt
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI


API_VERSION = os.getenv("API_VERSION", "2024-10-21")

TENANTS = [
    {"id": "tenant-adidas", "name": "Adidas"},
    {"id": "tenant-nike", "name": "Nike", "note": "low credits"},
    {"id": "tenant-startup", "name": "Startup X", "note": "no credits"},
]


def make_jwt(secret: str, tenant_id: str, user_email: str, expires_minutes: int = 60) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "iss": "inriver-auth",
        "aud": "ai-gateway",
        "tid": tenant_id,
        "sub": user_email,
        "name": "Demo User",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=expires_minutes)).timestamp()),
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def truncate_token(token: str) -> str:
    return token[:20] + "..." if len(token) > 23 else token


def make_endpoint(base_gateway_url: str) -> str:
    if base_gateway_url.endswith("/inrivermock"):
        return base_gateway_url
    if "/" not in base_gateway_url:
        return base_gateway_url + "/inrivermock"
    return base_gateway_url.rsplit("/", 1)[0] + "/inrivermock"


def call_gateway(endpoint: str, model: str, token: str):
    client = AzureOpenAI(
        azure_endpoint=endpoint,
        api_key="jwt-auth",
        api_version=API_VERSION,
        default_headers={"Authorization": f"Bearer {token}"},
        max_retries=0,
    )

    raw_response = client.chat.completions.with_raw_response.create(
        model=model,
        messages=[
            {
                "role": "user",
                "content": "Say hi and identify yourself in one short sentence.",
            }
        ],
        max_completion_tokens=60,
    )
    response = raw_response.parse()
    return response, raw_response.headers


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

    gateway_base = os.getenv("AI_GATEWAY_URL", "").strip()
    if not gateway_base:
        print("Set AI_GATEWAY_URL in src/.env")
        return 1

    endpoint = make_endpoint(gateway_base)
    model = os.getenv("MODEL_DEPLOYMENT", "gpt-5.2")
    jwt_secret = os.getenv("JWT_SECRET", "inriver-demo-secret-2026")

    print("🏢 Enterprise AI Gateway — JWT + Credit Service Demo")
    print(f"🎯 Endpoint: {endpoint}")
    print("=" * 56)

    for tenant in TENANTS:
        user = f"user1@{tenant['name'].lower().replace(' ', '')}.com"
        token = make_jwt(jwt_secret, tenant["id"], user)
        note = f" — {tenant['note']}" if tenant.get("note") else ""

        print(f"\n👤 Tenant: {tenant['name']} ({tenant['id']}){note}")
        print(f"   🔑 JWT: {truncate_token(token)}")

        try:
            response, headers = call_gateway(endpoint, model, token)
            content = (response.choices[0].message.content or "").strip()
            region = headers.get("x-ms-region", "unknown")
            remaining = headers.get("x-remaining-credits", "unknown")
            consumed = (
                headers.get("x-tokens-consumed")
                or str(getattr(response.usage, "total_tokens", "unknown"))
            )

            print(f"   ✅ Response: {content}")
            print(f"   🤖 Model: {response.model or model}")
            print(f"   🌍 Region: {region}")
            print(f"   🧾 Tokens consumed: {consumed}")
            print(f"   💰 Credits remaining: {remaining}")
        except APIStatusError as exc:
            body = ""
            if exc.response is not None:
                body = exc.response.text or ""
            message = body.strip() if body else str(exc)
            print(f"   🛑 {exc.status_code}: {message}")
        except Exception as exc:
            print(f"   ❌ Error: {exc}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
