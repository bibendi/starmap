#!/usr/bin/env bash
# Usage: script/mcp/get_token.sh [client_id] [client_secret]
# Gets a client_credentials token from Keycloak for an ApiClient.
# Reads defaults from .env.development if available.
#
# Examples:
#   script/mcp/get_token.sh                          # use defaults
#   script/mcp/get_token.sh my-client my-secret      # custom client

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLIENT_ID="${1:-starmap-ci-agent}"
CLIENT_SECRET="${2:-starmap-ci-agent-secret}"

# Load OIDC issuer from .env.development if available
if [ -f "$PROJECT_DIR/.env.development" ]; then
  set -a
  source "$PROJECT_DIR/.env.development"
  set +a
fi

KEYCLOAK_URL="${OIDC_ISSUER:-http://starmap.localhost:5101/realms/starmap}"
TOKEN_URL="$KEYCLOAK_URL/protocol/openid-connect/token"

TOKEN=$(curl -s -X POST "$TOKEN_URL" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  | jq -r '.access_token // empty')

if [ -z "$TOKEN" ]; then
  echo "Error: Failed to get token for client '$CLIENT_ID'" >&2
  curl -s -X POST "$TOKEN_URL" \
    -d "grant_type=client_credentials" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    | jq '.'
  exit 1
fi

echo "$TOKEN"
