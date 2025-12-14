#!/usr/bin/env python3
import re

with open("/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice Traders/MeetingDetailView.swift", "r") as f:
    content = f.read()

# Find and replace the detailsView property with a stub
# Look for: "private var detailsView: some View {" ... "    // MARK: - API Functions"

pattern = r'(    // MARK: - Details View\s+private var detailsView: some View \{)(.+?)(    // MARK: - API Functions)'

replacement = r'''\1
        EmptyView()
    }
    
    \3'''

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Verify it worked
if new_content != content:
    with open("/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice Traders/MeetingDetailView.swift", "w") as f:
        f.write(new_content)
    print("Successfully replaced detailsView with EmptyView stub")
else:
    print("Pattern did not match - no changes made")
