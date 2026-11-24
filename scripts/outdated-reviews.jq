# Input: `GET /repos/{owner}/{repo}/pulls/{number}/reviews`
# Args: --arg bot <login> --argjson posted <the run posted a review> --argjson unresolved <open bot threads>
# Output: the node ids of the bot's reviews to hide as outdated
[.[] | select(.user.login == $bot and (.body // "") != "")]
| sort_by(.submitted_at)
| if ($posted or $unresolved > 0) then .[:-1] else . end
| map(.node_id)
