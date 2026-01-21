import hashlib
import argparse
from pathlib import Path
import yaml

def detect_conflicts(primary_path, secondary_path, config_path, last_sync_manifest):
    conflicts = []
    
    # Load the specific config for this sync pair
    with open(config_path) as f:
        sync_config = yaml.safe_load(f)

    # Generic Loop: Works for ANY defined module
    for module in sync_config['sync_relationship']['sync_modules']:
        # ... [Standard hashing logic remains the same] ...
        pass
    
    return conflicts

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, help="Path to sync-config.yaml")
    args = parser.parse_args()
    # ... logic continues ...