# GUIDE

Quick ways to make the most out of a changeling.

## Bash

Handy hints for the bashful bunch. Each example reads `CHANGELOG-V3.md` from the
current folder and writes a new `.md` file next to it, leaving the changeling
untouched. They only need `awk`.

### Extract one changeset

Keeps the changeset with the given csid, from its heading up to the next
changeset. Every link in a changeset points inside it, so they all still work.

```sh
csid=ZOOM
awk -v csid="$csid" '/^## / { keep = index($3, csid "]") == 1 } keep' \
  CHANGELOG-V3.md > "$csid.md"
```

### Summaries without changes

Keeps each changeset heading, alert, and summary, followed by the Fixes and
Features descriptions without their links. The Changes are left out. Swap
`CHANGELOG-V3.md` for the file made by the previous example to summarise a
single changeset.

```sh
awk '
  /^## /          { keep = 1 }
  /^### Changes$/ { keep = 0 }
  !keep           { next }
  /^- \[/         { sub(/^- \[/, "- "); sub(/\]\(#[^)]*\)$/, "") }
                  { print }
' CHANGELOG-V3.md > summaries.md
```

### Dated changes with fixes and features only

Keeps the date of each changeset, its Changes heading, and every change with
only its `Fix:` or `Feat:` item. The `Problem:`, `Test:`, `Docs:`, and `Note:`
items go, along with their wrapped lines.

```sh
awk '
  /^## /          { print "## " substr($2, 2) "\n"; keep = 0; next }
  /^### Changes$/ { keep = 1 }
  !keep           { next }
  /^- /           { drop = !/^- \*\*(Fix|Feat):\*\*/ }
  !/^(- |  )/     { drop = 0 }
  !drop
' CHANGELOG-V3.md > dated-changes.md
```
