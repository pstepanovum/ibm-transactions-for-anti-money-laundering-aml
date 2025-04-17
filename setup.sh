#!/bin/bash

# Simple script to set up and run the AML detection database process

# Create database schema
echo "Creating database schema..."
sqlite3 aml_detection.db < schema.sql

# Run data extraction
echo "Running data extraction script..."
python extract.py

echo "Setup complete!"