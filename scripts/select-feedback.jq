# Input: the pull requests of one repository with their review threads, from GraphQL
#   repository.pullRequests.nodes[] { author { login } reviewThreads.nodes[] { isResolved isOutdated path
#     comments.nodes[] { author { login } createdAt body reactions.nodes[] { content createdAt user { login } } } } }
# Args: --arg bot <app slug> --arg owner <login> --arg since <ISO 8601 date>
# Only the owner's reactions and replies are feedback: what anyone else wrote is dropped.
# A thread counts when the owner commented or reacted in it since the given date.
# A "bot-finding" is a thread the bot's review opened and the owner reacted or replied to.
# An "owner-comment" is a thread the owner opened on a pull request the bot wrote.
def is_bot: . == $bot or . == ($bot + "[bot]");
[.data.repository.pullRequests.nodes[]
  | (.author.login | is_bot) as $by_bot
  | .reviewThreads.nodes[]
  | .comments.nodes[0] as $first
  | select(any(.comments.nodes[], $first.reactions.nodes[]; (.author.login // .user.login) == $owner and .createdAt >= $since))
  | {
      kind: (if ($first.author.login | is_bot) then "bot-finding" elif $first.author.login == $owner and $by_bot then "owner-comment" else null end),
      severity: ($first.body | if startswith("🟠 major") then "major" elif startswith("⚪ nit") then "nit" else null end),
      path,
      resolved: .isResolved,
      outdated: .isOutdated,
      comment: $first.body,
      reactions: [$first.reactions.nodes[] | select(.user.login == $owner) | .content],
      replies: [.comments.nodes[1:][]
        | select(.author.login == $owner or (.author.login | is_bot))
        | {author: (if .author.login == $owner then "owner" else "bot" end), body}]
    }
  | select(.kind == "owner-comment" or (.kind == "bot-finding" and ((.reactions | length) > 0 or any(.replies[]; .author == "owner"))))]
