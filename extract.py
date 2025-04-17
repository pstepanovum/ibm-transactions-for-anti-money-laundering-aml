import sqlite3
import csv
import os
import re
import random
from datetime import datetime
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
        accounts = set()
        payment_methods = set()

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
                payment_format = row[9]
                
                banks.add(source_bank)
                banks.add(dest_bank)
                payment_methods.add(payment_format)
                accounts.add((source_account, source_bank))
                accounts.add((dest_account, dest_bank))

        log_success(f"Found {len(banks)} unique banks, {len(payment_methods)} payment methods, "
                   f"{len(accounts)} accounts.")

        log_info("Populating lookup tables...")
        

        bankNames = ['Chase', 'Barclays', 'Deutsche', 'HSBC', 'Citi', 'Bank of America', 'Mizuho', 'Goldman Sachs']
        countries = ['USA', 'France', 'UK', 'Germany', 'Russia', 'China', 'Saudi Arabia', 'Japan']

        # Insert banks (assuming bank_id as country code, add default name)
        for bank_id in banks:
            randomBank = random.choice(bankNames)
            randomCountry = random.choice(countries)
            c.execute("INSERT OR IGNORE INTO BANK (bank_id, name, country) VALUES (?, ?, ?)", 
                     (bank_id, randomBank, randomCountry))
        log_success(f"Inserted {len(banks)} banks.")



        # Insert accounts with default type
        account_counter = 0
        for account_id, bank_id in accounts:
            randomAccountType = random.choice(['Individual', 'Corporate', 'Government'])
            c.execute("INSERT OR IGNORE INTO BANK_ACCOUNT (account_id, type, bank_id) VALUES (?, ?, ?)", 
                     (account_id, randomAccountType, bank_id))
            account_counter += 1
            if account_counter % 100 == 0 or account_counter == len(accounts):
                log_progress(account_counter, len(accounts), "Inserting Accounts", "Complete")
        log_success(f"Inserted {len(accounts)} accounts.")


        # Process patterns file
        log_highlight(f"Reading {txt_file} for laundering patterns...")
        with open(txt_file, 'r') as f:
            lines = f.readlines()


        pattern_mapping = {
            'FAN-IN': 11,
            'FAN-OUT': 12,
            'GATHER-SCATTER': 13,
            'SCATTER-GATHER': 14,
            'RANDOM': 15,
            'STACK': 16,
            'BIPARTITE': 17,
            'CYCLE': 18,
        }

        for pattern_name, pattern_id in pattern_mapping.items():
            c.execute("INSERT OR IGNORE INTO LAUNDERING_PATTERN (pattern_id, pattern_name) VALUES (?, ?)", (pattern_id, pattern_name))
        
        conn.commit()


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
            log_info(f"Processing {row_count} transaction rows from CSV file...")
            
            for i, row in enumerate(reader):
                if i % 100 == 0 or i == row_count - 1:
                    log_progress(i + 1, row_count, "Processing Transactions", "Complete")
                    
                if len(row) < 11:
                    log_warning(f"Skipping invalid row in {csv_file}: {row}")
                    continue
                try:
                    timestamp = row[0]

                    try:
                        correctedDT = datetime.strptime(timestamp.strip(), '%Y/%m/%d %H:%M')
                    except ValueError as time_e:
                        log_warning(f"Row {i+2}: Could not parse CSV timestamp '{timestamp}': {time_e}. Skipping row.")
                        continue

                    timestamp = correctedDT.strftime('%Y-%m-%d %H:%M:%S')
                    source_bank = row[1]
                    source_account = row[2]
                    dest_bank = row[3]
                    dest_account = row[4]
                    amount_received = round(float(row[5]), 2)  # Round to 2 decimal places
                    receiving_currency = row[6]
                    amount_sent = round(float(row[7]), 2)  # Round to 2 decimal places
                    payment_currency = row[8]
                    form_of_payment = row[9]
                    pattern_id = random.randint(11, 18)
                    is_laundering = int(row[10])
                    
                    c.execute("""
                        INSERT INTO FINANCIAL_TRANSACTION (
                            timestamp, source_account, source_bank, dest_account, dest_bank,
                            amount_received, currency_received, amount_sent, currency_sent,
                            form_of_payment, pattern_id
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        timestamp, source_account, source_bank, dest_account, dest_bank,
                        amount_received, receiving_currency, amount_sent, payment_currency,
                        form_of_payment, pattern_id
                    ))
                    transaction_count += 1
                except (ValueError, KeyError) as e:
                    log_error(f"Error processing transaction row {row}: {e}")
            log_success(f"Inserted {transaction_count} transactions.")

        conn.commit()
        log_success("Committed transaction data to database.")




        elapsed_time = timer.elapsed()
        log_highlight(f"Process completed in {elapsed_time:.2f} seconds")
        
        # Display summary box
        summary_data = {
            "Banks": len(banks),
            "Accounts": len(accounts),
            "Transactions": transaction_count,
           # "Patterns": pattern_count,
            #"Pattern Links": transaction_pattern_count
        }
        print_summary_box("AML DETECTION DATABASE POPULATION SUMMARY", summary_data, elapsed_time)


        # print(transactions_to_update)

    except sqlite3.Error as e:
        log_error(f"Database error: {e}")


    except Exception as e:
        log_error(f"Unexpected error: {e}")

    finally:
        conn.close()
        log_info("Database connection closed.")

if __name__ == "__main__":
    main()