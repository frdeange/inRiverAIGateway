from fastmcp import FastMCP

mcp = FastMCP("Product Catalog MCP Server")

PRODUCTS = [
    {"id": "SKU-001", "name": "Ergonomic Office Chair", "category": "furniture", "price": 599.99, "description": "Premium ergonomic chair with lumbar support"},
    {"id": "SKU-002", "name": "Standing Desk Pro", "category": "furniture", "price": 899.99, "description": "Electric adjustable standing desk"},
    {"id": "SKU-003", "name": "Wireless Keyboard", "category": "electronics", "price": 79.99, "description": "Bluetooth mechanical keyboard"},
    {"id": "SKU-004", "name": "4K Monitor 27\"", "category": "electronics", "price": 449.99, "description": "27-inch 4K IPS display"},
    {"id": "SKU-005", "name": "Desk Lamp LED", "category": "lighting", "price": 49.99, "description": "Adjustable LED desk lamp with USB charging"},
    {"id": "SKU-006", "name": "Cable Management Kit", "category": "accessories", "price": 24.99, "description": "Under-desk cable organizer set"},
    {"id": "SKU-007", "name": "Webcam 4K", "category": "electronics", "price": 149.99, "description": "4K webcam with auto-focus and noise cancellation"},
    {"id": "SKU-008", "name": "Ergonomic Mouse", "category": "electronics", "price": 69.99, "description": "Vertical ergonomic wireless mouse"},
]


@mcp.tool()
def get_product_catalog(category: str = "all") -> dict:
    """Get products from the catalog, optionally filtered by category."""
    normalized = category.strip().lower()
    if normalized == "all":
        filtered = PRODUCTS
    else:
        filtered = [p for p in PRODUCTS if p["category"].lower() == normalized]

    return {
        "category": category,
        "count": len(filtered),
        "products": filtered,
    }


@mcp.tool()
def search_products(query: str) -> dict:
    """Search products by name or description."""
    needle = query.strip().lower()
    filtered = [
        p
        for p in PRODUCTS
        if needle in p["name"].lower() or needle in p["description"].lower() or needle in p["category"].lower()
    ]

    return {
        "query": query,
        "count": len(filtered),
        "products": filtered,
    }


if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000)
