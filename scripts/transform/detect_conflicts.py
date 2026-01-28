import sys
import os

def detect_merge_conflicts(directory):
    """
    Scans a directory for standard Git merge conflict markers.
    """
    conflict_markers = [
        b'<<<<<<< ',
        b'=======\n',
        b'>>>>>>> '
    ]
    conflicts_found = []

    for root, dirs, files in os.walk(directory):
        if '.git' in dirs:
            dirs.remove('.git') # Skip .git directory
        
        for filename in files:
            filepath = os.path.join(root, filename)
            try:
                with open(filepath, 'rb') as f:
                    content = f.read()
                    if any(marker in content for marker in conflict_markers):
                        conflicts_found.append(filepath)
            except (IOError, OSError):
                continue
    
    if conflicts_found:
        print("CONFLICTS DETECTED in the following files:")
        for f in conflicts_found:
            print(f" - {f}")
        sys.exit(1)
    else:
        print("No conflicts detected.")
        sys.exit(0)

if __name__ == "__main__":
    target_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    detect_merge_conflicts(target_dir)
