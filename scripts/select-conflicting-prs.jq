# Input: `gh pr list --json number,headRefName,headRefOid,baseRefName,author,isCrossRepository,mergeable,isDraft`
# Args: --arg owner <login> --arg bot <app slug>
# Dependabot is left out: it rebases its own pull requests.
def trusted_author: .author.login as $a | [$owner, "app/\($bot)"] | index($a) != null;

[.[]
  | select(.isCrossRepository | not)
  | select(.isDraft | not)
  | select(trusted_author)
  | select(.mergeable == "CONFLICTING")
  | {number, headRefName, headRefOid, baseRefName}]
