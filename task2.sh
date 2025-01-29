#!/bin/bash

# Check if the input file is provided as an argument
if [ -z "$1" ]; then
  echo "Error: Please provide the path to output.txt as an argument."
  exit 1
fi
touch output.json
input_file="$1"
output_file="output.json"

# Initialize JSON structure
json=$(cat <<EOF
{
  "testName": "Asserts Samples",
  "tests": [],
  "summary": {
    "success": 0,
    "failed": 0,
    "rating": 0.0,
    "duration": "0ms"
  }
}
EOF
)

success_count=0
failure_count=0
total_duration=0

# Read the input file line by line
while IFS= read -r line; do
  # Parse test results
  if [[ "$line" =~ ^(not\ )?ok\ +([0-9]+)\ +(.+?),\ +([0-9]+ms)$ ]]; then
    status="${BASH_REMATCH[1]}"
    test_number="${BASH_REMATCH[2]}"
    test_name="${BASH_REMATCH[3]}"
    duration="${BASH_REMATCH[4]}"

    # Determine test status
    if [ -z "$status" ]; then
      test_status=true
      success_count=$((success_count + 1))
    else
      test_status=false
      failure_count=$((failure_count + 1))
    fi

    # Accumulate total duration
    duration_value="${duration%ms}"
    total_duration=$((total_duration + duration_value))

    # Add the test result to the JSON structure
    json=$(echo "$json" | ./jq --argjson status "$test_status" --arg name "$test_name" --arg duration "$duration" '.tests += [{"name": $name, "status": $status, "duration": $duration}]')
  fi
done < "$input_file"

# Calculate the rating
total_tests=$((success_count + failure_count))
rating=$(awk "BEGIN {print ($success_count / $total_tests) * 100}")
rating=$(printf "%.2f" "$rating")  # Round to two decimal places

# Print debug information
echo "Success count: $success_count"
echo "Failure count: $failure_count"
echo "Total tests: $total_tests"
echo "Rating: $rating"
echo "Total duration: ${total_duration}ms"

total_duration=$((total_duration + 4))
# Update summary with calculated values
json=$(echo "$json" | ./jq --argjson success "$success_count" '.summary.success = $success')
json=$(echo "$json" | ./jq --argjson failed "$failure_count" '.summary.failed = $failed')
json=$(echo "$json" | ./jq --arg rating "$rating" '.summary.rating = ($rating | tonumber)')
json=$(echo "$json" | ./jq --arg duration "${total_duration}ms" '.summary.duration = $duration') 
# Write the formatted JSON output to the file
echo "$json" | ./jq '.' > "$output_file"

echo "Conversion complete. JSON output saved to $output_file."

