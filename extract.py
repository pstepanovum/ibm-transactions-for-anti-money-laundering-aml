import sqlite3
import csv
import os
from utils.utils import (
    log_success, log_info, log_warning, log_error, log_highlight,
    log_progress, print_summary_box, Timer
)

def main():
    timer = Timer()
    
    log_highlight("Starting AML Detection Database Population")
    log_info("Checking for required input files...")
    
    # Check if input files exist
    csv_file = 'data/HI-Small_Trans.csv'
    txt_file = 'data/HI-Small_Patterns.txt'
    if not os.path.exists(csv_file):
        log_error(f"File not found: {csv_file}")
        return
    if not os.path.exists(txt_file):
        log_error(f"File not found: {txt_file}")
        return
    
    log_success(f"Found required input files: {csv_file} and {txt_file}")

    try:
        # Connect to the database
        conn = sqlite3.connect('aml_detection.db')
        log_success("Connected to database: aml_detection.db")
        c = conn.cursor()

        # First pass: collect unique values for lookup tables
        banks = set()
        currencies = set()
        payment_methods = set()
        accounts = set()

        log_info(f"Reading {csv_file} for lookup values...")
        with open(csv_file, 'r') as csvfile:
            reader = csv.reader(csvfile)
            try:
                next(reader)  # Skip header
            except StopIteration:
                log_error(f"{csv_file} is empty.")
                return
                
            # Count total rows for progress bar
            csvfile.seek(0)
            row_count = sum(1 for row in csv.reader(csvfile)) - 1  # Exclude header
            csvfile.seek(0)
            next(csv.reader(csvfile))  # Skip header again
            
            log_info(f"Processing {row_count} rows from CSV file...")
            
            for i, row in enumerate(reader):
                if i % 100 == 0 or i == row_count - 1:
                    log_progress(i + 1, row_count, "Reading CSV", "Complete")
                
                if len(row) < 11:
                    log_warning(f"Skipping invalid row in {csv_file}: {row}")
                    continue
                source_bank = row[1]
                source_account = row[2]
                dest_bank = row[3]
                dest_account = row[4]
                receiving_currency = row[6]
                payment_currency = row[8]
                payment_format = row[9]
                
                banks.add(source_bank)
                banks.add(dest_bank)
                currencies.add(receiving_currency)
                currencies.add(payment_currency)
                payment_methods.add(payment_format)
                accounts.add((source_account, source_bank))
                accounts.add((dest_account, dest_bank))

        log_success(f"Found {len(banks)} unique banks, {len(currencies)} currencies, "
                   f"{len(payment_methods)} payment methods, {len(accounts)} accounts.")

        log_info("Populating lookup tables...")
        
        # Insert banks
        for bank_id in banks:
            c.execute("INSERT OR IGNORE INTO BANK (bank_id) VALUES (?)", (bank_id,))
        log_success(f"Inserted {len(banks)} banks.")

        # Insert currencies
        for currency_code in currencies:
            c.execute("INSERT OR IGNORE INTO CURRENCY (currency_code) VALUES (?)", (currency_code,))
        log_success(f"Inserted {len(currencies)} currencies.")

        # Insert payment methods
        for method_name in payment_methods:
            c.execute("INSERT OR IGNORE INTO PAYMENT_METHOD (method_name) VALUES (?)", (method_name,))
        log_success(f"Inserted {len(payment_methods)} payment methods.")

        # Insert accounts
        account_counter = 0
        for account_id, bank_id in accounts:
            c.execute("INSERT OR IGNORE INTO ACCOUNT (account_id, bank_id) VALUES (?, ?)", (account_id, bank_id))
            account_counter += 1
            if account_counter % 100 == 0 or account_counter == len(accounts):
                log_progress(account_counter, len(accounts), "Inserting Accounts", "Complete")
        log_success(f"Inserted {len(accounts)} accounts.")

        # Get payment method ID mapping
        c.execute("SELECT method_id, method_name FROM PAYMENT_METHOD")
        payment_method_map = {name: id for id, name in c.fetchall()}
        log_info("Created payment method mapping.")

        # Second pass: insert transactions
        log_highlight(f"Reading {csv_file} for transactions...")
        with open(csv_file, 'r') as csvfile:
            reader = csv.reader(csvfile)
            next(reader)  # Skip header
            transaction_count = 0
            
            # Count total rows again
            csvfile.seek(0)
            row_count = sum(1 for row in csv.reader(csvfile)) - 1  # Exclude header
            csvfile.seek(0)
            next(csv.reader(csvfile))  # Skip header again
            
            for i, row in enumerate(reader):
                if i % 100 == 0 or i == row_count - 1:
                    log_progress(i + 1, row_count, "Processing Transactions", "Complete")
                    
                if len(row) < 11:
                    log_warning(f"Skipping invalid row in {csv_file}: {row}")
                    continue
                try:
                    timestamp = row[0]  # Assuming format like '2022/09/01 00:20' is SQLite-compatible
                    source_bank = row[1]
                    source_account = row[2]
                    dest_bank = row[3]
                    dest_account = row[4]
                    amount_received = round(float(row[5]), 2)  # Round to 2 decimal places
                    receiving_currency = row[6]
                    amount_paid = round(float(row[7]), 2)  # Round to 2 decimal places
                    payment_currency = row[8]
                    payment_format = row[9]
                    is_laundering = int(row[10])
                    
                    payment_method_id = payment_method_map[payment_format]
                    
                    c.execute("""
                        INSERT INTO FINANCIAL_TRANSACTION (
                            timestamp, source_account_id, source_bank_id, dest_account_id, dest_bank_id,
                            amount_received, receiving_currency_code, amount_paid, payment_currency_code,
                            payment_method_id, is_laundering
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        timestamp, source_account, source_bank, dest_account, dest_bank,
                        amount_received, receiving_currency, amount_paid, payment_currency,
                        payment_method_id, is_laundering
                    ))
                    transaction_count += 1
                except (ValueError, KeyError) as e:
                    log_error(f"Error processing transaction row {row}: {e}")
            log_success(f"Inserted {transaction_count} transactions.")

        conn.commit()
        log_success("Committed transaction data to database.")

        # Process patterns file
        log_highlight(f"Reading {txt_file} for laundering patterns...")
        with open(txt_file, 'r') as f:
            lines = f.readlines()
        
        current_pattern = None
        pattern_id = None
        pattern_count = 0
        transaction_pattern_count = 0
        
        log_info(f"Processing {len(lines)} lines from patterns file...")

        for i, line in enumerate(lines):
            if i % 100 == 0 or i == len(lines) - 1:
                log_progress(i + 1, len(lines), "Processing Patterns", "Complete")
                
            line = line.strip()
            if line.startswith("BEGIN LAUNDERING ATTEMPT"):
                pattern_name = line.split("-")[1].strip()
                pattern_description = line.split(":")[1].strip() if ":" in line else ""
                
                c.execute("INSERT INTO LAUNDERING_PATTERN (pattern_name, pattern_description) VALUES (?, ?)",
                         (pattern_name, pattern_description))
                pattern_id = c.lastrowid
                current_pattern = pattern_name
                pattern_count += 1
                log_info(f"Processing pattern: {pattern_name}")
            elif line and current_pattern and "," in line:
                try:
                    parts = line.split(',')
                    if len(parts) < 10:
                        log_warning(f"Skipping invalid pattern transaction line: {line}")
                        continue
                    timestamp = parts[0]
                    source_bank = parts[1]
                    source_account = parts[2]
                    dest_bank = parts[3]
                    dest_account = parts[4]
                    
                    c.execute("""
                        SELECT transaction_id FROM FINANCIAL_TRANSACTION
                        WHERE timestamp = ? AND source_bank_id = ? AND source_account_id = ?
                        AND dest_bank_id = ? AND dest_account_id = ?
                    """, (timestamp, source_bank, source_account, dest_bank, dest_account))
                    
                    result = c.fetchone()
                    if result:
                        transaction_id = result[0]
                        c.execute("INSERT OR IGNORE INTO TRANSACTION_PATTERN (transaction_id, pattern_id) VALUES (?, ?)",
                                 (transaction_id, pattern_id))
                        transaction_pattern_count += 1
                    else:
                        log_warning(f"No matching transaction found for pattern line: {line}")
                except Exception as e:
                    log_error(f"Error processing pattern line {line}: {e}")

        conn.commit()
        log_success(f"Inserted {pattern_count} patterns and {transaction_pattern_count} transaction-pattern links.")

        elapsed_time = timer.elapsed()
        log_highlight(f"Process completed in {elapsed_time:.2f} seconds")
        
        # Display summary box
        summary_data = {
            "Banks": len(banks),
            "Currencies": len(currencies),
            "Payment Methods": len(payment_methods),
            "Accounts": len(accounts),
            "Transactions": transaction_count,
            "Patterns": pattern_count,
            "Pattern Links": transaction_pattern_count
        }
        print_summary_box("AML DETECTION DATABASE POPULATION SUMMARY", summary_data, elapsed_time)

    except sqlite3.Error as e:
        log_error(f"Database error: {e}")
    except Exception as e:
        log_error(f"Unexpected error: {e}")
    finally:
        conn.close()
        log_info("Database connection closed.")

if __name__ == "__main__":
    main()