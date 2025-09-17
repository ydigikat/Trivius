#!/usr/bin/env python3
import sys
import re
from pathlib import Path

def parse_resource_utilization(content):
    """Extract resource utilization from main report"""
    print("\n=== Resource Utilization ===")
    
    # Look for the resource usage table in cursus_rpt.html
    # Find Logic row
    logic_match = re.search(r'Logic\s*</td>\s*<td[^>]*>\s*(\d+)/(\d+)\s*</td>\s*<td[^>]*>\s*(\d+)%', content, re.DOTALL)
    if logic_match:
        used, total, percent = logic_match.groups()
        print(f"Logic: {used}/{total} ({percent}%)")
    
    # Look for LUT,ALU,ROM16 breakdown
    lut_alu_match = re.search(r'--LUT,ALU,ROM16\s*</td>\s*<td[^>]*>\s*(\d+)\((\d+)\s*LUT,\s*(\d+)\s*ALU,\s*(\d+)\s*ROM16\)', content, re.DOTALL)
    if lut_alu_match:
        total_logic, luts, alus, rom16 = lut_alu_match.groups()
        print(f"  LUTs: {luts}")
        print(f"  ALUs: {alus}")
        print(f"  ROM16: {rom16}")
    
    # Look for SSRAM(RAM16) row
    ssram_match = re.search(r'--SSRAM\(RAM16\)\s*</td>\s*<td[^>]*>\s*(\d+)', content, re.DOTALL)
    if ssram_match:
        ssram = ssram_match.group(1)
        print(f"  SSRAM: {ssram}")

def parse_max_frequency_table(content):
    """Extract data from Max Frequency Summary table"""    
    
    # Find the table section
    table_match = re.search(r'<h2><a name="Max_Frequency_Report">.*?</h2>\s*<table>(.*?)</table>', content, re.DOTALL)
    
    if table_match:
        table_content = table_match.group(1)
        
        # Extract data rows (skip header)
        row_pattern = r'<tr>\s*<td>(\d+)</td>\s*<td>([^<]+)</td>\s*<td>([^<]+)</td>\s*<td>([^<]+)</td>\s*<td>(\d+)</td>\s*<td>([^<]+)</td>\s*</tr>'
        
        found_data = False
        for match in re.finditer(row_pattern, table_content):
            no, clock_name, constraint, actual_fmax, logic_level, entity = match.groups()
            print(f"Clock: {clock_name} | Constraint: {constraint} | Actual: {actual_fmax} | Logic Level: {logic_level}")
            found_data = True
        
        if not found_data:
            print("No frequency data found")
    else:
        print("Max Frequency table not found")

def parse_timing_slack(content):
    """Extract timing slack from path tables"""
    
    
    # Extract worst setup slack from Setup Paths Table
    setup_table_match = re.search(r'<h3><a name="Setup_Slack_Table">Setup Paths Table</a></h3>.*?<table.*?>(.*?)</table>', content, re.DOTALL)
    
    if setup_table_match:
        setup_table = setup_table_match.group(1)
        # Find first data row (worst slack)
        setup_row = re.search(r'<tr>\s*<td>\d+</td>\s*<td>([^<]+)</td>', setup_table)
        if setup_row:
            setup_slack = setup_row.group(1)
            print(f"Worst Setup Slack: {setup_slack} ns")
    
    # Extract worst hold slack from Hold Paths Table  
    hold_table_match = re.search(r'<h3><a name="Hold_Slack_Table">Hold Paths Table</a></h3>.*?<table.*?>(.*?)</table>', content, re.DOTALL)
    
    if hold_table_match:
        hold_table = hold_table_match.group(1)
        # Find first data row (worst slack)
        hold_row = re.search(r'<tr>\s*<td>\d+</td>\s*<td>([^<]+)</td>', hold_table)
        if hold_row:
            hold_slack = hold_row.group(1)
            print(f"Worst Hold Slack: {hold_slack} ns")

def parse_tns_table(content):
    """Extract TNS data"""
    
    
    # Find TNS table
    table_match = re.search(r'<h2><a name="Total_Negative_Slack_Report">.*?</h2>.*?<table.*?>(.*?)</table>', content, re.DOTALL)
    
    if table_match:
        table_content = table_match.group(1)
        
        # Look for first Setup and Hold entries
        setup_match = re.search(r'<td>([^<]+)</td>\s*<td>Setup</td>\s*<td>([^<]+)</td>', table_content)
        hold_match = re.search(r'<td>([^<]+)</td>\s*<td>Hold</td>\s*<td>([^<]+)</td>', table_content)
        
        if setup_match:
            print(f"Setup TNS: {setup_match.group(2)}")
        if hold_match:
            print(f"Hold TNS: {hold_match.group(2)}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 parse_reports.py <main_report_file> <timing_file>")
        sys.exit(1)
    
    main_report_file = Path(sys.argv[1])
    timing_file = Path(sys.argv[2])
    
    # Parse resource utilization from main report
    if main_report_file.exists():
        try:
            with open(main_report_file, 'r') as f:
                content = f.read()
            parse_resource_utilization(content)
        except Exception as e:
            print(f"Error parsing main report file: {e}")
    else:
        print(f"Main report file not found: {main_report_file}")
    
    # Parse timing report
    if timing_file.exists():
        try:
            with open(timing_file, 'r') as f:
                content = f.read()
            
            print("\n=== Timing Analysis ===")
            parse_max_frequency_table(content)
            parse_timing_slack(content)
            parse_tns_table(content)
            
        except Exception as e:
            print(f"Error parsing timing file: {e}")
    else:
        print(f"Timing file not found: {timing_file}")

if __name__ == "__main__":
    main()