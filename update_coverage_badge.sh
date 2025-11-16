#!/bin/bash

# A script to generate a test coverage report and update the badge in README.md

# --- Strict Mode ---
set -euo pipefail


# Check if lcov.info was created
if [ ! -f "coverage/lcov.info" ]; then
    echo "Error: coverage/lcov.info not found. Test coverage generation failed."
    exit 1
fi

# 2. Calculate total coverage percentage
echo "Calculating total coverage..."

# Use awk to sum up the Lines Found (LF) and Lines Hit (LH) from the lcov.info file
total_lines=$(awk -F: '/^LF:/ {s+=$2} END {print s}' coverage/lcov.info)
hit_lines=$(awk -F: '/^LH:/ {s+=$2} END {print s}' coverage/lcov.info)

if [ -z "$total_lines" ] || [ "$total_lines" -eq 0 ]; then
    coverage_pct=0
else
    # Use bc for floating point arithmetic and printf to format as an integer
    coverage_pct=$(echo "scale=2; ($hit_lines / $total_lines) * 100" | bc | xargs printf "%.0f")
fi

echo "Coverage: $coverage_pct%"

# 3. Determine badge color based on percentage
color="red"
if (( coverage_pct > 50 )); then color="yellow"; fi
if (( coverage_pct > 75 )); then color="green"; fi
if (( coverage_pct > 90 )); then color="brightgreen"; fi

# 4. Update README.md
badge_url="https://img.shields.io/badge/coverage-$coverage_pct%25-$color"
full_badge_markdown="![]($badge_url)"
readme_file="README.md"

# This uses sed to find the line with the coverage badge and replace it.
echo "Updating README.md with new badge..."
sed -i "s|!\[\](https://img.shields.io/badge/coverage-.*)|$full_badge_markdown|" "$readme_file"

echo "Badge updated successfully!"