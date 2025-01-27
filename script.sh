#!/bin/bash

# Check if the required arguments are provided
if [ $# -ne 3 ]; then
  echo "Usage: $0 <file_name> <dojo_host> <dojo_auth_token>"
  exit 1
fi

# Assign arguments to variables
FILE_NAME=$1
DOJO_HOST=$2
DOJO_AUTH_TOKEN=$3

# Determine the scan type based on the file name
if [[ "$FILE_NAME" == "gitleaks.json" ]]; then
  SCAN_TYPE="Gitleaks Scan"
elif [[ "$FILE_NAME" == "semgrep.json" ]]; then
  SCAN_TYPE="Semgrep JSON Report"
else
  echo "Unsupported file type: $FILE_NAME"
  exit 1
fi

# DefectDojo API endpoint
URL="$DOJO_HOST/api/v2/import-scan/"

# Temporary file for storing the response
RESPONSE_FILE=$(mktemp)

# Ensure the temporary file is cleaned up on script exit
trap 'rm -f "$RESPONSE_FILE"' EXIT

# Make the API request with curl
HTTP_CODE=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" -X POST "$URL" \
  -H "Authorization: Token $DOJO_AUTH_TOKEN" \
  -F "file=@$FILE_NAME" \
  -F "active=true" \
  -F "verified=true" \
  -F "scan_type=$SCAN_TYPE" \
  -F "minimum_severity=Low" \
  -F "engagement=20")

# Handle the response
if [[ "$HTTP_CODE" == "201" ]]; then
  echo "Scan results imported successfully for $FILE_NAME"
else
  echo "Failed to import scan results for $FILE_NAME"
  echo "HTTP Status Code: $HTTP_CODE"
  echo "Response:"
  cat "$RESPONSE_FILE"
  exit 1
fi