# Input: `GET /repos/{owner}/{repo}/issues/comments`
# Args: --arg owner <login> --arg bot <app slug>
[.[]
  | select(.user.login == $owner)
  | select(.body | test("@\($bot)(?![A-Za-z0-9-])"; "i"))
  | {
      comment_id: .id,
      number: (.issue_url | split("/") | last | tonumber),
      is_pr: (.html_url | contains("/pull/")),
      body,
      html_url
    }]
