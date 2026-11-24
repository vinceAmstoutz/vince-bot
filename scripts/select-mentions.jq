# Input: `GET /repos/{owner}/{repo}/issues/comments` or `GET /repos/{owner}/{repo}/pulls/comments`
# Args: --arg owner <login> --arg bot <app slug>
# A review comment keeps the thread to answer in: `reply_to` is the thread's first comment.
[.[]
  | select(.user.login == $owner)
  | select(.body | test("@\($bot)(?![A-Za-z0-9-])|(^|\n)\\s*/bot(?![A-Za-z0-9_-])"; "i"))
  | (.pull_request_review_id != null) as $review
  | {
      comment_id: .id,
      number: ((.issue_url // .pull_request_url) | split("/") | last | tonumber),
      is_pr: ($review or (.html_url | contains("/pull/"))),
      type: (if $review then "review" else "issue" end),
      reply_to: (if $review then (.in_reply_to_id // .id) else null end),
      body,
      html_url
    }]
