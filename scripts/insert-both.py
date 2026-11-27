"""Usage: insert-both.py <base> <ours> <theirs>

Prints <theirs> with every block of lines <ours> inserted into <base>, each placed after what <theirs> inserted at the
same place. Exits 3, printing nothing, when <ours> changed or removed a line of <base>, or when <theirs> changed or
removed the line a block of <ours> goes before: those need a person or an agent.
"""

import re
import subprocess
import sys

HUNK = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")


def hunks(old, new):
    diff = subprocess.run(
        ["git", "diff", "--no-index", "--no-color", "--no-ext-diff", "-U0", old, new],
        capture_output=True, text=True, check=False,
    )
    if diff.returncode > 1:
        sys.exit(diff.stderr)
    found = []
    for line in diff.stdout.splitlines():
        match = HUNK.match(line)
        if match:
            old_start, old_count, new_start, new_count = match.groups()
            found.append((int(old_start), int(old_count or 1), int(new_start), int(new_count or 1)))
    return found


def theirs_line(base_line, theirs_hunks):
    offset = 0
    for old_start, old_count, new_start, new_count in theirs_hunks:
        last = old_start if old_count == 0 else old_start + old_count - 1
        if old_count and old_start <= base_line <= last:
            return None
        if last < base_line:
            offset += new_count - old_count
    return base_line + offset


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read().splitlines(keepends=True)


def main(base_path, ours_path, theirs_path):
    base, ours, theirs = read(base_path), read(ours_path), read(theirs_path)
    theirs_hunks = hunks(base_path, theirs_path)
    blocks = []
    for old_start, old_count, new_start, new_count in hunks(base_path, ours_path):
        if old_count:
            sys.exit(3)
        before = old_start + 1
        position = len(theirs) if before > len(base) else theirs_line(before, theirs_hunks)
        if position is None:
            sys.exit(3)
        if before <= len(base):
            position -= 1
        blocks.append((position, ours[new_start - 1:new_start - 1 + new_count]))
    for position, lines in reversed(blocks):
        theirs[position:position] = lines
    sys.stdout.write("".join(theirs))


if __name__ == "__main__":
    main(*sys.argv[1:])
