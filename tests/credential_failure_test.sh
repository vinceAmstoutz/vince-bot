#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

is_credential_failure() { printf '%s\n' "$1" > "$work/log"; sh "$root/scripts/credential-failure.sh" "$work/log"; }

is_credential_failure 'Claude AI usage limit reached|1795460000' || fail 'usage limit'
is_credential_failure 'API Error: 401 {"type":"error","error":{"type":"authentication_error","message":"OAuth token has expired."}}' || fail 'expired token'
is_credential_failure 'Invalid API key · Please run /login' || fail 'invalid key'
is_credential_failure 'API Error: 429 rate_limit_error: Number of request tokens has exceeded your rate limit' || fail 'rate limit'
is_credential_failure 'Your credit balance is too low to access the Anthropic API.' || fail 'credit balance'
is_credential_failure 'API Error: 403 {"type":"error","error":{"type":"permission_error","message":"OAuth authentication is currently not allowed for this organization."}}' || fail 'permission'

is_credential_failure 'Error: Reached max turns (150)' && fail 'max turns is not a credential failure'
is_credential_failure 'Error: ENOENT: no such file or directory, open composer.json' && fail 'a file error is not a credential failure'
is_credential_failure 'The rate limiter tests failed: 3 of 12 limits exceeded' && fail 'project text mentioning limits is not a credential failure'

echo 'credential_failure_test: ok'
