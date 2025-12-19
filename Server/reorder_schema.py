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
    """Extract individual CREATE TABLE statements"""
    pattern = r'CREATE TABLE `(\w+)`\s*\((.*?)\)\s*ENGINE'
    matches = re.finditer(pattern, schema, re.DOTALL)
    
    tables = {}
    for match in matches:
        table_name = match.group(1)
        table_def = match.group(0)
        tables[table_name] = table_def
    
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
    schema = read_schema('/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/database_schema.sql')
    tables = extract_tables(schema)
    sorted_table_names = topological_sort(tables)
    
    # Write reordered schema
    output = "-- Database Schema (Reordered for FK Dependencies)\n\n"
    for table_name in sorted_table_names:
        output += tables[table_name] + ";\n\n"
    
    with open('/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/database_schema_ordered.sql', 'w') as f:
        f.write(output)
    
    print(f"✅ Schema reordered. Table creation order:")
    for i, table in enumerate(sorted_table_names, 1):
        print(f"  {i}. {table}")

if __name__ == '__main__':
    main()
