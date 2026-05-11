import os
import sys

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import AzureOpenAI


API_VERSION = "2024-10-21"


def load_tiers() -> list[tuple[str, str, str]]:
    tiers: list[tuple[str, str, str]] = []
    for key, value in os.environ.items():
        if key.startswith("SMARTAI_") and key.endswith("_KEY") and value.strip():
            tier_key = key.removeprefix("SMARTAI_").removesuffix("_KEY")
            description = os.getenv(f"SMARTAI_{tier_key}_DESC", "").strip()
            tiers.append((tier_key.lower(), value.strip(), description))
    return sorted(tiers, key=lambda tier: tier[0])


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))
    gateway_url = os.getenv("AI_GATEWAY_URL", "").strip()
    tiers = load_tiers()

    if not gateway_url:
        print("Set AI_GATEWAY_URL in src/.env")
        return 1

    if not tiers:
        print("Set at least one SMARTAI_*_KEY in src/.env or the environment.")
        return 1

    # Use /smartai path
    smart_endpoint = gateway_url.rsplit("/", 1)[0] + "/smartai"

    print("🧠 Smart AI Gateway — Product-Based Model Routing")
    print(f"🎯 Endpoint: {smart_endpoint}")
    print("=" * 60)

    for tier, key, description in tiers:
        print(f"\n🏷️  Product: \x1b[1;33m{tier}\x1b[0m ({description})")
        print(f"   📤 Requested model: gpt-5.2")

        client = AzureOpenAI(
            azure_endpoint=smart_endpoint,
            api_key=key,
            api_version=API_VERSION,
            default_headers={"api-key": key, "Ocp-Apim-Subscription-Key": key},
        )

        try:
            raw_response = client.chat.completions.with_raw_response.create(
                model="gpt-5.2",
                messages=[
                    {"role": "user", "content": "Say hi and name yourself in one sentence."}
                ],
                max_completion_tokens=60,
            )
            response = raw_response.parse()

            actual_model = response.model or "unknown"
            region = raw_response.headers.get("x-ms-region", "")
            model_tier = raw_response.headers.get("x-model-tier", "N/A")

            print(f"   ✅ Response: {response.choices[0].message.content}")
            print(f"   🤖 Actual model: \x1b[1;36m{actual_model}\x1b[0m")
            print(f"   🌍 x-ms-region: \x1b[1;32m{region or 'on-premises'}\x1b[0m")
            print(f"   🏷️  x-model-tier: {model_tier}")
            print(f"   📊 Tokens: {response.usage.total_tokens}")

        except Exception as exc:
            print(f"   ❌ Error: {exc}")

    print("\n" + "=" * 60)
    print(f"💡 All {len(tiers)} requests sent model='gpt-5.2' — the gateway overrode it per product.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
