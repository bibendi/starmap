#!/usr/bin/env bash
# Usage: script/mcp/demo.sh
# Full demo of ApiClient authentication.
# Prerequisites: bin/rails db:seed (creates teams + ApiClient records)
#
# Steps:
#   1. Ensure ApiClient record exists in database
#   2. Get client_credentials token from Keycloak
#   3. Call tools/list
#   4. Call team_metrics for an authorized team
#   5. Call team_metrics for a non-existent team

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== ApiClient Auth Demo ==="
echo ""

# Step 1: Ensure ApiClient record exists
echo "--- Step 1: Sync ApiClient record ---"
cd "$PROJECT_DIR"
bin/rails runner - <<RUBY
client = ApiClient.find_or_initialize_by(oidc_client_id: 'starmap-ci-agent')
if client.new_record?
  team_ids = Team.pluck(:id)
  client.update!(
    name: 'starmap-ci-agent',
    permissions: ['teams:read'],
    team_ids: team_ids,
    enabled: true
  )
  puts "Created ApiClient ##{client.id} with #{team_ids.size} teams"
else
  puts "ApiClient ##{client.id} already exists"
end
RUBY
echo ""

# Step 2: Get token
echo "--- Step 2: Get client_credentials token ---"
TOKEN=$("$SCRIPT_DIR/get_token.sh")
echo "Token acquired (${#TOKEN} chars)"
echo ""

# Step 3: Show JWT claims
echo "--- JWT Claims ---"
echo "$TOKEN" | cut -d. -f2 | python3 -c "
import sys, base64, json
padded = sys.stdin.read().strip() + '=='
try:
    decoded = json.loads(base64.urlsafe_b64decode(padded))
    print(json.dumps(decoded, indent=2))
except:
    print('Failed to decode')
" 2>/dev/null || echo "(decode failed)"
echo ""

# Step 4: tools/list
echo "--- Step 3: tools/list ---"
ID=1 "$SCRIPT_DIR/call.sh" "$TOKEN" tools/list
echo ""

# Step 5: team_metrics for authorized team
echo "--- Step 4: team_metrics for 'Backend Team' ---"
ID=2 "$SCRIPT_DIR/call.sh" "$TOKEN" tools/call '{"name":"team_metrics","arguments":{"team_name":"Backend Team"}}'
echo ""

# Step 6: team_metrics for non-existent team
echo "--- Step 5: team_metrics for 'Unknown Team' ---"
ID=3 "$SCRIPT_DIR/call.sh" "$TOKEN" tools/call '{"name":"team_metrics","arguments":{"team_name":"Unknown Team"}}'
echo ""

echo "=== Demo Complete ==="
