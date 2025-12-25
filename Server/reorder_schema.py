#!/usr/bin/env python3
"""
Reorders database schema to respect foreign key dependencies.
Tables with no foreign keys are created first, then tables that depend on them.
"""

import re

def read_schema(filepath):
    with open(filepath, 'r') as f:
        return f.read()

def extract_tables(schema):
    """Extract individual CREATE TABLE statements by splitting on semicolons"""
    tables = {}
    
    # Split by lines to find CREATE TABLE statements
    lines = schema.split('\n')
    current_table = []
    current_name = None
    
    for line in lines:
        if line.startswith('CREATE TABLE'):
            current_table = [line]
            # Extract table name
            match = re.search(r'CREATE TABLE `(\w+)`', line)
            if match:
                current_name = match.group(1)
        elif current_table:
            current_table.append(line)
            if line.rstrip().endswith(';'):
                # End of table definition
                table_def = '\n'.join(current_table)
                if current_name:
                    tables[current_name] = table_def
                current_table = []
                current_name = None
    
    return tables

def get_foreign_keys(table_def):
    """Extract table names referenced by foreign keys"""
    pattern = r'FOREIGN KEY \(`\w+`\) REFERENCES `(\w+)`'
    matches = re.findall(pattern, table_def)
    return set(matches)

def topological_sort(tables):
    """Sort tables so dependencies are created first"""
    # Build dependency graph
    dependencies = {}
    for table_name, table_def in tables.items():
        dependencies[table_name] = get_foreign_keys(table_def)
    
    sorted_tables = []
    visited = set()
    visiting = set()
    
    def visit(table):
        if table in visited:
            return
        if table in visiting:
            return  # Skip circular deps
        
        visiting.add(table)
        
        # Visit dependencies first
        for dep in dependencies.get(table, set()):
            if dep in tables:  # Only if dep exists in our schema
                visit(dep)
        
        visiting.remove(table)
        visited.add(table)
        sorted_tables.append(table)
    
    for table_name in tables:
        visit(table_name)
    
    return sorted_tables

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
schema = read_schema(os.path.join(script_dir, "database_schema.sql"))
    tables = extract_tables(schema)
    sorted_table_names = topological_sort(tables)
    
    # Write reordered schema
    output = "-- Database Schema (Reordered for FK Dependencies)\n\n"
    for table_name in sorted_table_names:
        output += tables[table_name] + "\n\n"
    
    with open(os.path.join(script_dir, "database_schema_ordered.sql"), 'w') as f:
        f.write(output)
    
    print(f"✅ Schema reordered. Table creation order:")
    for i, table in enumerate(sorted_table_names, 1):
        print(f"  {i}. {table}")

if __name__ == '__main__':
    main()
