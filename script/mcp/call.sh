#!/usr/bin/env bash
# Usage: script/mcp/call.sh <token> <method> [arguments_json]
# Calls the MCP endpoint with a Bearer token.
#
# Examples:
#   TOKEN=$(script/mcp/get_token.sh)
#   script/mcp/call.sh "$TOKEN" tools/list
#   script/mcp/call.sh "$TOKEN" tools/call '{"name":"team_metrics","arguments":{"team_name":"Backend Team"}}'

set -euo pipefail

TOKEN="${1:?Usage: call.sh <token> <method> [arguments]}"
METHOD="${2:?Usage: call.sh <token> <method> [arguments]}"
PARAMS="${3:-}"

MCP_URL="${MCP_URL:-http://localhost:3000/mcp}"
ID="${ID:-1}"

JSON_BODY=$(jq -n \
  --arg method "$METHOD" \
  --argjson id "$ID" \
  '{"jsonrpc":"2.0","id":$id,"method":$method}')

if [ -n "$PARAMS" ]; then
  JSON_BODY=$(echo "$JSON_BODY" | jq --argjson params "$PARAMS" '. + {params: $params}')
fi

curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$JSON_BODY" \
  | jq '.'
