#!/usr/bin/env python3
"""Update AI_CHANGELOG.md with new entry"""

# Read the new entry
with open('/home/runner/work/VoxGuard/VoxGuard/docs/AI_CHANGELOG_UPDATE.md', 'r') as f:
    new_entry = f.read()

# Read the existing changelog
with open('/home/runner/work/VoxGuard/VoxGuard/docs/AI_CHANGELOG.md', 'r') as f:
    existing = f.read()

# Combine (new entry + existing)
combined = new_entry + "\n" + existing

# Write back
with open('/home/runner/work/VoxGuard/VoxGuard/docs/AI_CHANGELOG.md', 'w') as f:
    f.write(combined)

print("Changelog updated successfully")
