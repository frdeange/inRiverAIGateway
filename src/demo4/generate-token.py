import argparse
import os
import sys
from datetime import datetime, timedelta, timezone

import jwt
from dotenv import load_dotenv


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate HS256 JWT for AI Gateway demo.")
    parser.add_argument("--tenant", required=True, help="Tenant ID (tid claim)")
    parser.add_argument("--user", required=True, help="User email (sub claim)")
    parser.add_argument("--expires", type=int, default=60, help="Expiration in minutes (default: 60)")
    return parser.parse_args()


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))
    args = parse_args()

    now = datetime.now(timezone.utc)
    secret = os.getenv("JWT_SECRET", "inriver-demo-secret-2026")

    payload = {
        "iss": "inriver-auth",
        "aud": "ai-gateway",
        "tid": args.tenant,
        "sub": args.user,
        "name": "Demo User",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=args.expires)).timestamp()),
    }

    token = jwt.encode(payload, secret, algorithm="HS256")
    print(token)
    return 0


if __name__ == "__main__":
    sys.exit(main())
