# Input: `gh pr list --json number,headRefName,headRefOid,author,isCrossRepository,statusCheckRollup,commits`
# Args: --arg owner <login> --arg bot <app slug>
def failed: (.conclusion // .state // "") as $s | ["FAILURE", "ERROR", "TIMED_OUT", "STARTUP_FAILURE", "ACTION_REQUIRED"] | index($s) != null;
def trusted_author: .author.login as $a | [$owner, "app/dependabot", "app/\($bot)"] | index($a) != null;
def last_commit_by_bot: (.commits[-1].authors // []) | any(((.login // "") + " " + (.email // "")) | contains($bot));

[.[]
  | select(.isCrossRepository | not)
  | select(trusted_author)
  | select(any(.statusCheckRollup[]?; failed))
  | select(last_commit_by_bot | not)
  | {number, headRefName, headRefOid}]
