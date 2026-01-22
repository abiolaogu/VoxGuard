from mcp.server.fastmcp import FastMCP
import subprocess

# Initialize the MCP Server
mcp = FastMCP("repo-operations")

@mcp.tool()
def derive_product(source_repo: str, new_product_name: str, config_path: str):
    """Triggers the Product Derivation workflow in GitHub."""
    cmd = [
        "gh", "workflow", "run", "derive-product.yml",
        "--repo", source_repo,
        "-f", f"config_file={config_path}"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout or result.stderr

@mcp.tool()
def trigger_sync(target_repo: str, sync_path: str):
    """Triggers the Bidirectional Sync workflow."""
    cmd = [
        "gh", "workflow", "run", "bidirectional-sync.yml",
        "-f", f"target_repo={target_repo}",
        "-f", f"sync_path={sync_path}"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout or result.stderr

if __name__ == "__main__":
    mcp.run()
