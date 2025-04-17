#!/bin/bash

# Simple script to set up and run the AML detection database process

# Check for data directory and required files
echo "Checking data folder and required files..."

DATA_DIR="data"
PATTERNS_FILE="$DATA_DIR/HI-Small_Patterns.txt"
TRANS_FILE="$DATA_DIR/HI-Small_Trans.csv"

if [ ! -d "$DATA_DIR" ]; then
  echo "Error: '$DATA_DIR' folder is missing."
  exit 1
fi

if [ ! -f "$PATTERNS_FILE" ]; then
  echo "Error: Required file '$PATTERNS_FILE' is missing."
  exit 1
fi

if [ ! -f "$TRANS_FILE" ]; then
  echo "Error: Required file '$TRANS_FILE' is missing."
  exit 1
fi

echo "Data folder and required files found. Continuing setup..."

# Create database schema
echo "Creating database schema..."
sqlite3 aml_detection.db < schema.sql

# Run data extraction
echo "Running data extraction script..."
python extract.py

echo "Setup complete!"
