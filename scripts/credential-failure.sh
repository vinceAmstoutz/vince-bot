#!/bin/sh
# Usage: credential-failure.sh <claude log>   Succeeds when Claude stopped because its credential was refused or exhausted.
set -eu

grep -Eqi \
  -e 'usage limit reached' \
  -e 'API Error: (401|403|429)' \
  -e 'authentication_error|permission_error|rate_limit_error' \
  -e 'OAuth token (has expired|is invalid|was revoked)' \
  -e 'Invalid API key' \
  -e 'Please run /login' \
  -e 'credit balance is too low' \
  "$1"
