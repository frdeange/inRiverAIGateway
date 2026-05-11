import os
import sys

from dotenv import load_dotenv
from openai import OpenAI


def build_client() -> tuple[OpenAI, str, str, str]:
    ai_gateway_url = os.getenv("AI_GATEWAY_URL", "").strip()
    local_model_url = os.getenv("LOCAL_MODEL_URL", "http://localhost:11434/v1").strip() or "http://localhost:11434/v1"
    model_name = os.getenv("LOCAL_MODEL_NAME", "phi4-mini").strip() or "phi4-mini"

    if ai_gateway_url:
        subscription_key = os.getenv("AI_GATEWAY_KEY", "").strip()
        if not subscription_key:
            raise ValueError("Set AI_GATEWAY_KEY when AI_GATEWAY_URL is configured.")

        return (
            OpenAI(
                base_url=ai_gateway_url.rstrip("/"),
                api_key=subscription_key,
                default_headers={
                    "Ocp-Apim-Subscription-Key": subscription_key,
                    "x-model-target": "local",
                },
            ),
            model_name,
            ai_gateway_url.rstrip("/"),
            "🔒 Mode: AI Gateway → Local Model (governed)",
        )

    return (
        OpenAI(
            base_url=local_model_url.rstrip("/"),
            api_key="ollama",
        ),
        model_name,
        local_model_url.rstrip("/"),
        "🏠 Mode: Local Model (direct)",
    )


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

    try:
        client, model_name, resolved_endpoint, mode_label = build_client()
    except ValueError as exc:
        print(exc)
        return 1

    print(mode_label)
    print(f"🎯 Endpoint: {resolved_endpoint}")
    print(f"🧠 Model: {model_name}")

    raw_response = client.chat.completions.with_raw_response.create(
        model=model_name,
        messages=[
            {"role": "system", "content": "You are a concise assistant."},
            {"role": "user", "content": "What is the value of AI Gateway for local or on-prem models in one sentence?"},
        ],
        max_completion_tokens=100,
    )
    response = raw_response.parse()

    print(f"✅ Response: {response.choices[0].message.content}")
    print(
        f"📊 Tokens: {response.usage.prompt_tokens} prompt + {response.usage.completion_tokens} completion = "
        f"{response.usage.total_tokens} total"
    )
    print(f"🌍 x-ms-region: \x1b[1;32m{raw_response.headers.get('x-ms-region', '')}\x1b[0m")
    if raw_response.headers.get("x-backend-region"):
        print(f"🔀 x-backend-region: \x1b[1;36m{raw_response.headers.get('x-backend-region')}\x1b[0m")
    return 0


if __name__ == "__main__":
    sys.exit(main())
