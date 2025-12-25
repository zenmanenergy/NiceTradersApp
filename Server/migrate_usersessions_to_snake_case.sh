#!/bin/bash
# Migration script to rename usersessions table and SessionId column to snake_case

cd "$(dirname "$0")" || exit 1

echo "Running migration: usersessions -> user_sessions, SessionId -> session_id"
echo ""

./venv/bin/python3 migrate_usersessions_to_snake_case.py

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "Migration script completed successfully!"
else
    echo ""
    echo "Migration script failed with exit code $exit_code"
fi

exit $exit_code
