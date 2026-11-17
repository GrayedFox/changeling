#!/usr/bin/env bash
# Checks changelings against SPECIFICATION.md, then runs every GUIDE.md example
# on them. Usage: tests/run.sh [file...], defaults to tests/CHANGELOG-*.md
set -uo pipefail
export LC_ALL=C

root=$(cd "$(dirname "$0")/.." && pwd)
[ $# -gt 0 ] || set -- "$root"/tests/CHANGELOG-*.md
guide_input=CHANGELOG-V3.md # the file name the GUIDE.md examples read
fails=0

check() { # check <name> <command...>: prints ok, or FAIL plus what the command printed
  local name=$1 out
  shift
  if out=$("$@" 2>&1); then
    echo "ok   $name"
  else
    echo "FAIL $name"
    [ -z "$out" ] || sed 's/^/     /' <<<"$out"
    fails=$((fails + 1))
  fi
}

# Helpers

none() { ! grep "$@"; } # passes when grep matches nothing, printing any matches
anchor() { tr 'A-Z' 'a-z' | sed 's/^#* //; s/ /-/g'; } # spec: lowercased heading, spaces as hyphens
visible() { awk '/<!--/ { c = 1 } !c { print } /-->/ { c = 0 }' "$1"; } # drops HTML comments
headings() { grep '^## ' "$file"; }
dates() { headings | cut -d' ' -f2 | tr -d '['; }
csids() { headings | cut -d' ' -f3 | cut -c1-4; }
labels() { headings | sed 's/.*]\[\(.*\)]$/\1/'; }
items() { awk '/^##+ / { s = $2 } (s == "Fixes" || s == "Features") && /^- \[/' "$1"; }

refs() { # refs <file> <comm flag>: -23 lists labels used but not defined, -13 defined but not used
  comm "$2" <(visible "$1" | grep -o ']\[[^]]*]' | sed 's/^]\[//; s/]$//' | tr 'A-Z' 'a-z' | sort -u) \
    <(visible "$1" | sed -n 's/^\[\([^]]*\)\]: .*/\1/p' | tr 'A-Z' 'a-z' | sort -u) | none .
}

anchors() { # anchors <file>: lists (#anchor) links that match no change heading
  comm -23 <(grep -o '](#[^)]*)' "$1" | sed 's/^](#//; s/)$//' | sort -u) \
    <(grep '^#### ' "$1" | anchor | sort -u) | none .
}

# Changelogs

t_file_name() { basename "$file" | none -vE -- '-[A-Za-z0-9]+\.md$'; }

t_heading_format() {
  headings >/dev/null && headings | none -vE '^## \[[0-9]{4}-[0-9]{2}-[0-9]{2} [A-Z]{4}\]\[[^]]+\]$'
}

t_real_dates() {
  local d
  # shortcut: GNU date only, swap for an awk calendar check if macOS needs to run this
  for d in $(dates); do [ "$(date -d "$d" +%F 2>/dev/null)" = "$d" ] || echo "$d"; done | none .
}

t_newest_first() { dates | sort -rc; }
t_unique_csids() { csids | sort | uniq -d | none .; }
t_unique_labels() { labels | tr 'A-Z' 'a-z' | sort | uniq -d | none .; }

# Changesets

t_alert() {
  awk 'BEGIN { ok["> [!CAUTION]|> BREAKING CHANGES"] = ok["> [!WARNING]|> MAJOR CHANGES"] = ok["> [!NOTE]|> STANDARD CHANGES"] = 1 }
       function chk() { if (h && (!ok[l[1] "|" l[2]] || l[3] != "" || alerts != 1)) print h }
       /^## / { chk(); h = $0; n = alerts = 0; delete l; next }
       h && (n || NF) && n < 3 { l[++n] = $0 }
       /^> \[!/ { alerts++ }
       END { chk() }' "$file" | none .
}

t_summary() {
  awk 'function chk() { if (h && !s) print h }
       /^## / { chk(); h = $0; s = 0; pre = 1; next }
       /^### / { pre = 0 }
       h && pre && NF && !/^> / && !/^\[[^]]+\]: / { s = 1 }
       END { chk() }' "$file" | none .
}

t_changeset_link() {
  visible "$file" | awk '
    function chk() { if (h && url !~ /^(https:\/\/|file:)/) print h ": " (url ? url : "no definition before the first section") }
    /^## / { chk(); h = $0; l = $0; sub(/.*\]\[/, "", l); sub(/\]$/, "", l); l = tolower(l); url = ""; pre = 1; next }
    /^### / { pre = 0 }
    h && pre && tolower($1) == "[" l "]:" { url = $2 }
    END { chk() }' | none .
}

t_breaking_alert() {
  awk 'function chk() { if (h && caution != breaking) print h }
       /^## / { chk(); h = $0; caution = breaking = 0; next }
       /^> \[!CAUTION\]$/ { caution = 1 }
       /^#### [A-Z]+ breaking / { breaking = 1 }
       END { chk() }' "$file" | none .
}

t_level_three() { none -E '^(#|##|####+) *(Fixes|Features|Changes) *$' "$file"; }

t_sections() {
  awk 'function chk() { if (h && s !~ /^(Fixes |Features |Fixes Features )Changes $/) print h ": " s }
       /^## / { chk(); h = $0; s = "" }
       /^####? / && !h { print "before the first changeset: " $0 }
       /^### / { s = s $2 " " }
       END { chk() }' "$file" | none .
}

# Fixes and Features

t_lists() {
  awk 'function chk() { if (s && !n) print h " " s ": empty"; s = "" }
       /^#/ { chk() }
       /^## / { h = $2 " " $3 }
       /^### (Fixes|Features)$/ { s = $2; n = 0; next }
       s && NF { n++; if (!/^- \[[^]]+\]\(#[a-z0-9-]+\)$/) print h " " s ": " $0 }
       END { chk() }' "$file" | none .
}

t_links_land() {
  awk 'function anchor(s) { s = tolower(s); gsub(/ /, "-", s); return s }
       /^## / { cs = substr($3, 1, 4) }
       /^### / { s = $2 }
       /^#### / { t = ($3 == "breaking" ? $4 : $3); h = $0; sub(/^#### /, "", h); type[cs, anchor(h)] = t }
       (s == "Fixes" || s == "Features") && /^- \[/ { a = $0; sub(/.*\(#/, "", a); sub(/\)$/, "", a); n++; item[n] = a; sec[n] = s; set[n] = cs }
       END {
         for (i = 1; i <= n; i++) {
           t = type[set[i], item[i]]
           if (t == "") print item[i] ": no change with that anchor in " set[i]
           else if ((sec[i] == "Fixes") != (t == "fix")) print item[i] ": a " t " listed under " sec[i]
         }
       }' "$file" | none .
}

t_linked_once() {
  { grep '^#### ' "$file" | anchor; items "$file" | sed 's/.*(#\(.*\))$/\1/'; } | sort | uniq -c |
    awk '$1 != 2 { print $2 ": seen " $1 " time(s) across change headings and list links, want 2" }' | none .
}

# Changes

t_change_headings() {
  awk '/^## / { csid = substr($3, 1, 4) }
       /^### / { s = $2 }
       /^#### / && (s != "Changes" || $2 != csid || !/^#### [A-Z]+ (breaking )?(fix|feat)( [a-z0-9-]+)+$/)' "$file" | none .
}

t_unique_changes() { grep '^#### ' "$file" | anchor | sort | uniq -d | none .; }

t_change_blocks() {
  awk 'BEGIN { rank["Problem"] = 1; rank["Fix"] = rank["Feat"] = 2; rank["Test"] = 3; rank["Docs"] = 4; rank["Note"] = 5 }
       function chk() { if (h && !(seen["Problem"] && seen[want])) print h ": missing " (seen["Problem"] ? want : "Problem"); h = "" }
       /^#/ { chk() }
       /^### Changes$/ { changes = 1; next }
       /^#?#?# / { changes = 0 }
       /^#### / { h = $0; want = ($3 == "feat" || $4 == "feat") ? "Feat" : "Fix"; last = 0; delete seen; next }
       h && /^- \*\*[A-Za-z]+:\*\* / {
         k = $2; gsub(/[*:]/, "", k)
         if (!(k in rank) || rank[k] <= last || (rank[k] == 2 && k != want)) print h ": " k " is out of place"
         else { last = rank[k]; seen[k] = 1 }
         next
       }
       h && NF && !/^  [^ ]/ { print h ": stray line: " $0 }
       changes && !h && NF { print "stray line under ### Changes: " $0 }
       END { chk() }' "$file" | none .
}

# GUIDE.md examples, run verbatim in a scratch folder on a copy of the changeling

guide() { # guide <heading> [sed script]: runs the first code block under "### <heading>"
  local code
  code=$(awk -v h="### $1" '$0 == h { f = 1; next } f && /^```/ { if (n++) exit; next } f && n' \
    "$root/GUIDE.md" | sed "${2:-}")
  [ -n "$code" ] || { echo "no example under ### $1"; return 1; }
  (cd "$scratch" && bash -euo pipefail -c "$code")
}

t_guide_changeset() { # t_guide_changeset <csid>
  local out=$scratch/$1.md
  guide "Extract one changeset" "s/^csid=.*/csid=$1/" &&
    head -n1 "$out" | grep -q "^## \[[^ ]* $1\]" &&
    [ "$(grep -c '^## ' "$out")" -eq 1 ] &&
    grep '^#### ' "$out" | none -v "^#### $1 " &&
    [ "$(grep -c "^#### $1 " "$out")" -eq "$(grep -c "^#### $1 " "$file")" ] &&
    refs "$out" -23 && anchors "$out"
}

t_guide_summaries() {
  local out=$scratch/summaries.md
  guide "Summaries without changes" &&
    none -E '^### Changes|^#### |\]\(#' "$out" &&
    diff <(headings) <(grep '^## ' "$out") &&
    [ "$(grep -c '^> \[!' "$out")" -eq "$(grep -c '^> \[!' "$file")" ] &&
    diff <(items "$file" | sed 's/^- \[\(.*\)](#[^)]*)$/- \1/') <(grep '^- ' "$out") &&
    refs "$out" -23
}

t_guide_dated_changes() {
  local out=$scratch/dated-changes.md
  guide "Dated changes with fixes and features only" &&
    diff <(dates | sed 's/^/## /') <(grep '^## ' "$out") &&
    grep '^### ' "$out" | none -vx '### Changes' &&
    diff <(grep '^#### ' "$file") <(grep '^#### ' "$out") &&
    diff <(awk '/^#/ { k = 0 } /^- / { k = $2 ~ /^\*\*(Fix|Feat):\*\*$/ } k' "$file" | grep .) \
      <(grep -v '^#' "$out" | grep .)
}

tmp=$(mktemp -d)
trap 'rm -rf "${tmp:?}"' EXIT

for file in "$@"; do
  echo "== ${file#"$root"/}"
  [ -f "$file" ] || { echo "FAIL no such file"; fails=$((fails + 1)); continue; }
  scratch=$(mktemp -d "$tmp/XXXXXX")
  cp "$file" "$scratch/$guide_input"

  check "file name ends in -\$major.md" t_file_name
  check "every level two heading reads ## [YYYY-MM-DD CSID][link]" t_heading_format
  check "changeset dates are real calendar days" t_real_dates
  check "changesets are sorted newest first" t_newest_first
  check "csids are unique" t_unique_csids
  check "changeset link labels are unique" t_unique_labels
  check "changesets open with exactly one alert block, then a blank line" t_alert
  check "changesets have a summary statement" t_summary
  check "changeset links are defined before the sections as https or file URLs" t_changeset_link
  check "the breaking alert is used if, and only if, a change is breaking" t_breaking_alert
  check "Fixes, Features, and Changes are only ever level three" t_level_three
  check "sections are Fixes, Features, or both, then Changes" t_sections
  check "Fixes and Features each hold one non-empty list of [description](#anchor)" t_lists
  check "list links land on a change of the matching type in their changeset" t_links_land
  check "every change is linked exactly once" t_linked_once
  check "change headings read #### CSID [breaking ]fix|feat title, under Changes" t_change_headings
  check "change headings are unique" t_unique_changes
  check "change blocks are Problem, Fix or Feat, then Test, Docs, Note" t_change_blocks
  check "every reference link has a definition" refs "$file" -23
  check "every link definition is used" refs "$file" -13
  check "every #anchor link lands on a change" anchors "$file"
  check "guide: extract the first changeset" t_guide_changeset "$(csids | head -n1)"
  check "guide: extract the last changeset" t_guide_changeset "$(csids | tail -n1)"
  check "guide: summaries without changes" t_guide_summaries
  check "guide: dated changes with fixes and features only" t_guide_dated_changes
  echo
done

[ "$fails" -eq 0 ] && echo "all checks passed" || { echo "$fails check(s) failed"; exit 1; }
