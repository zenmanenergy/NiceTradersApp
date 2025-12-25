#!/bin/bash
# Run comprehensive notification service tests

cd "$(dirname "$0")" || exit 1

echo "=========================================="
echo "Running Notification Service Unit Tests"
echo "=========================================="
echo ""

# Run the tests with verbose output
python3 test_notification_service.py -v

echo ""
echo "=========================================="
echo "Test run complete"
echo "=========================================="
