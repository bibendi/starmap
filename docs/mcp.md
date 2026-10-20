# MCP usage

Starmap exposes read-only tools through the JSON-RPC endpoint `POST /mcp`.
See [Authentication Architecture](auth.md) for sessions, OIDC Bearer tokens,
machine client setup and authorization rules. Send requests with
`Content-Type: application/json`. Use `tools/list` to discover available tools.

Both tools declare `readOnlyHint: true`, `destructiveHint: false`,
`idempotentHint: true` and `openWorldHint: false`.

## Access rules

All authenticated User roles can read the period catalogue. An ApiClient must be
enabled and have `teams:read`; `units:read` alone or empty permissions are insufficient.
The catalogue is global and does not grant administrative access.

Team metrics use `TeamPolicy` for Users. An ApiClient must be enabled, have
`teams:read` and have access to the requested team. Catalogue discovery does
not expand that scope.

## Discover assessment periods

`assessment_periods` takes no arguments. It returns the complete global catalogue,
including periods without team ratings, all types (`monthly`, `quarterly`,
`semiannual`, `annual`, `custom`) and all statuses (`draft`, `active`,
`closed`, `archived`). Entries are ordered by `start_date`, `end_date`, then
`id`, ascending. An empty catalogue returns `{"periods": []}`.

Each entry in `periods` contains only:

| Field | Meaning |
| --- | --- |
| `id` | Integer ID to pass to `team_metrics` as `period_id` |
| `name` | Display name, identical to the metrics response's `period_name` |
| `period_kind` | One of the five period types above |
| `status` | One of the four statuses above |
| `start_date`, `end_date` | Measured interval, ISO dates `YYYY-MM-DD` |
| `evaluation_start_date`, `evaluation_end_date` | Evaluation window, ISO dates `YYYY-MM-DD` |
| `is_current` | Stored boolean flag; independent of status and dates |

A closed period may be current. If none is current, discovery still works and
all entries have `is_current: false`. The catalogue contains no ratings or user data
and does not change periods or their current flags.

## Request team metrics

`team_metrics` accepts:

| Argument | Required | Meaning |
| --- | --- | --- |
| `team_name` | Yes | Exact team name |
| `period_id` | No | Positive integer ID from `assessment_periods`; defaults to the current period |

The response contains `team`, `period_id`, `period_name`, `coverage_index`,
`maturity_index`, `red_zones_count` and `key_person_risks_count`.
An unknown or invalid explicit period ID returns an error rather than falling
back to current. Without a current period, discover a period and supply its ID.

## Example: catalogue → historical metrics

First request the catalogue:

```json
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"assessment_periods","arguments":{}}}
```

Successful tool responses contain a JSON string in `result.content[0].text`
and `result.isError: false`. Parse that string and select an entry from
`periods` by its dates or name. If the selected entry has `id: 42`, pass that
value as `period_id`:

```json
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"team_metrics","arguments":{"team_name":"Backend","period_id":42}}}
```

The metrics response identifies the selected entry through `period_id: 42`
and the same `period_name` as its catalogue `name`.
This sequence also recovers from the `No current assessment period` error.
Catalogue access does not grant access to another team's metrics.
Policy denials return `result.isError: true`; failed authentication returns HTTP 401.
