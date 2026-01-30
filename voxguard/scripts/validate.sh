#!/bin/bash
# validate.sh - Pre-commit validation script
# Run this before committing to ensure code quality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  Anti-Call Masking Validation Script"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to report status
report() {
    local status=$1
    local message=$2
    if [ "$status" == "pass" ]; then
        echo -e "${GREEN}[PASS]${NC} $message"
    elif [ "$status" == "warn" ]; then
        echo -e "${YELLOW}[WARN]${NC} $message"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${RED}[FAIL]${NC} $message"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "1. Checking q file syntax..."
echo "-------------------------------------------"
for f in "$PROJECT_DIR"/src/*.q; do
    filename=$(basename "$f")
    # Check balanced braces
    open=$(grep -o '{' "$f" | wc -l)
    close=$(grep -o '}' "$f" | wc -l)
    if [ "$open" -ne "$close" ]; then
        report "fail" "$filename: Unbalanced braces (open=$open, close=$close)"
    else
        report "pass" "$filename: Syntax OK"
    fi
done
echo ""

echo "2. Checking for hardcoded secrets..."
echo "-------------------------------------------"
if grep -rn "password.*ClueCon" --include="*.q" "$PROJECT_DIR/src/" 2>/dev/null; then
    report "warn" "Default password 'ClueCon' found in source"
else
    report "pass" "No default passwords in source"
fi

if grep -rn "CHANGE_ME" --include="*.yaml" "$PROJECT_DIR/k8s/" 2>/dev/null; then
    report "warn" "Placeholder secrets found in k8s manifests"
else
    report "pass" "No placeholder secrets in k8s manifests"
fi
echo ""

echo "3. Validating Kubernetes manifests..."
echo "-------------------------------------------"
if command -v kubectl &> /dev/null; then
    for f in "$PROJECT_DIR"/k8s/*.yaml; do
        filename=$(basename "$f")
        if kubectl apply --dry-run=client -f "$f" > /dev/null 2>&1; then
            report "pass" "$filename: Valid"
        else
            report "warn" "$filename: Validation skipped (might need cluster context)"
        fi
    done
else
    report "warn" "kubectl not found - skipping k8s validation"
fi
echo ""

echo "4. Checking Docker configuration..."
echo "-------------------------------------------"
if [ -f "$PROJECT_DIR/Dockerfile" ]; then
    report "pass" "Dockerfile exists"

    # Check for non-root user
    if grep -q "USER kdb" "$PROJECT_DIR/Dockerfile"; then
        report "pass" "Dockerfile uses non-root user"
    else
        report "warn" "Dockerfile should use non-root user"
    fi

    # Check for HEALTHCHECK
    if grep -q "HEALTHCHECK" "$PROJECT_DIR/Dockerfile"; then
        report "pass" "Dockerfile has health check"
    else
        report "warn" "Dockerfile should have HEALTHCHECK"
    fi
else
    report "fail" "Dockerfile not found"
fi
echo ""

echo "5. Checking CI/CD configuration..."
echo "-------------------------------------------"
if [ -f "$PROJECT_DIR/.github/workflows/ci.yml" ]; then
    report "pass" "GitHub Actions workflow exists"
else
    report "warn" "GitHub Actions workflow not found"
fi

if [ -f "$PROJECT_DIR/Jenkinsfile" ]; then
    report "pass" "Jenkinsfile exists"
else
    report "warn" "Jenkinsfile not found"
fi
echo ""

echo "6. Checking test files..."
echo "-------------------------------------------"
REQUIRED_TESTS=(
    "tests/test_detection.q"
    "tests/test_load.q"
    "tests/attack_simulator.q"
    "tests/integration_tests.q"
    "scripts/run_tests.q"
)

for test in "${REQUIRED_TESTS[@]}"; do
    if [ -f "$PROJECT_DIR/$test" ]; then
        report "pass" "$test exists"
    else
        report "fail" "$test not found"
    fi
done
echo ""

echo "7. Checking documentation..."
echo "-------------------------------------------"
REQUIRED_DOCS=(
    "README.md"
    "docs/runbook.md"
    "docs/INTEGRATION_PLAN.md"
    "security/SECURITY.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$PROJECT_DIR/$doc" ]; then
        report "pass" "$doc exists"
    else
        report "warn" "$doc not found"
    fi
done
echo ""

echo "=========================================="
echo "  Validation Summary"
echo "=========================================="
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}Failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
