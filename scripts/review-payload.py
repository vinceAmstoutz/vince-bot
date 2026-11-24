"""Usage: review-payload.py <review.json> <files.json> <head sha> <footer>

Prints the GitHub review payload for the agent's review: comments on lines of
the diff become inline comments, the others join the review body. Prints
nothing when the review holds no comment.
"""
import json
import re
import sys

HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@")


def commentable_lines(patch):
    """Maps each line of the new file shown in the patch to its hunk index."""
    lines = {}
    hunk = -1
    number = 0
    for row in (patch or "").split("\n"):
        header = HUNK.match(row)
        if header:
            hunk += 1
            number = int(header.group(1))
            continue
        if hunk < 0 or row.startswith("-") or row.startswith("\\"):
            continue
        lines[number] = hunk
        number += 1
    return lines


def main(review_path, files_path, head, footer):
    with open(review_path, encoding="utf-8") as handle:
        review = json.load(handle)
    with open(files_path, encoding="utf-8") as handle:
        files = {entry["filename"]: commentable_lines(entry.get("patch")) for entry in json.load(handle)}

    inline, outside = [], []
    for comment in review.get("comments", []):
        path, line, start = comment.get("path"), comment.get("line"), comment.get("start_line")
        lines = files.get(path, {})
        same_hunk = start is None or (start in lines and line in lines and lines[start] == lines[line] and start < line)
        if line in lines and same_hunk:
            entry = {"path": path, "line": line, "side": "RIGHT", "body": comment["body"]}
            if start is not None:
                entry.update({"start_line": start, "start_side": "RIGHT"})
            inline.append(entry)
        else:
            place = f"`{path}` line {start}-{line}" if start else f"`{path}` line {line}"
            outside.append(f"- {place}: {comment['body']}")

    if not inline and not outside:
        return

    summary = review.get("summary", "").strip()

    body = summary
    if outside:
        body += "\n\n**Outside the diff**\n\n" + "\n".join(outside)
    body += "\n\n---\n" + footer
    print(json.dumps({"commit_id": head, "event": "COMMENT", "body": body, "comments": inline}))


if __name__ == "__main__":
    main(*sys.argv[1:5])
