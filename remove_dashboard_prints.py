#!/usr/bin/env python3
"""
Remove all print() statements from DashboardView.swift, including the loops they're in
"""

import re

file_path = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice Traders/DashboardView.swift"

with open(file_path, 'r') as f:
    content = f.read()

# Count original prints
original_count = content.count('print(')
print(f"Found {original_count} print() statements")

# Remove all lines that contain print()
lines = content.split('\n')
new_lines = []
skip_next_brace = False

for i, line in enumerate(lines):
    # Check if this line has a print statement
    if 'print(' in line:
        # Skip this line
        continue
    
    new_lines.append(line)

new_content = '\n'.join(new_lines)

# Now remove empty for loops - look for patterns like:
# for (index, something) in collection.enumerated() {
# }
# (with possibly empty or whitespace-only content between)

# Remove for loops that only contain whitespace/comments
pattern = r'for\s*\([^)]+\)\s*in\s*[^{]+\.enumerated\(\)\s*\{\s*(?://[^\n]*)?\s*\}'
new_content = re.sub(pattern, '', new_content)

# Also handle multi-line for loops with just whitespace
lines = new_content.split('\n')
result_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Check if this line starts a for loop with enumerated()
    if re.search(r'for\s*\([^)]+\)\s*in\s*\S+\.enumerated\(\)\s*\{', line):
        # Look ahead to see if the loop is empty (only whitespace until })
        j = i + 1
        loop_content_empty = True
        while j < len(lines):
            next_line = lines[j]
            if '}' in next_line and next_line.strip() == '}':
                # Found closing brace, skip the loop
                i = j + 1
                break
            elif next_line.strip() and not next_line.strip().startswith('//'):
                # Non-empty, non-comment line found
                loop_content_empty = False
                break
            j += 1
        
        if loop_content_empty and j < len(lines):
            # Skip this loop
            continue
    
    result_lines.append(line)
    i += 1

new_content = '\n'.join(result_lines)

# Clean up any double blank lines created by removing prints
new_content = re.sub(r'\n\n\n+', '\n\n', new_content)

# Write back
with open(file_path, 'w') as f:
    f.write(new_content)

new_count = new_content.count('print(')
print(f"Removed {original_count - new_count} print() statements")
print(f"Remaining print() statements: {new_count}")
print("Done!")
