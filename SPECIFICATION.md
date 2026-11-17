# SPECIFICATION

A changeling is a changelog that's easy to read, write, and parse.

## Prose

- `changeling` means a file that fully conforms to the changeling spec
- `changelog` means a file suffixed with a major version token
- `changeset` means an entry in a changelog that groups a set of changes
- `change` means an entry in a changeset that is distinct from any other
- `fix` means a change that updates an **existing** process or capability
- `feat` means a change that adds an **absent** process or capability

## Format

Changesets must adhere to the following format:

```md
## [$date csid][link]

<alert-block>

<summary-statement>

[link]: link-to-relevant-resource

### Fixes

- [description](#csid-fix-title)
- [description](#csid-breaking-fix-title)

### Features

- [description](#csid-feat-title)

### Changes

#### CSID fix title

<change-block>

#### CSID breaking fix title

<change-block>

#### CSID feat title

<change-block>
```

## Blocks

Blocks are dynamic, strictly formatted content that allow for consumers of a
changeling to reliably match on one or more tokens.

### Alerts

Alert blocks come in three different flavours and each of them means something
different:

- `breaking` signals changes that void or break an existing contract, promise,
  or functionality. This is the strongest signal an author has, reserved for
  changes that an audience need to know about and must act on in order to
  continue to safely use or operate your software, system, or product.
- `major` signals changes that don't void or break anything but that warrant
  special treatment due to their scope, breadth, or impact. A one-line change
  that introduces a notable change in behaviour could be reasonably considered
  major. These are changes that your audience will want to know about, but that
  they need not act on.
- `standard` signals business-as-usual changes that are routine and well scoped
  such as small fixes, maintenance, and internal improvements. These are changes
  your audience might want to know about, but that requires no action on their
  part.

Syntax:

```md
> [!CAUTION]
> BREAKING CHANGES

> [!WARNING]
> MAJOR CHANGES

> [!NOTE]
> STANDARD CHANGES
```

### Changes

A Change block comes in two different flavours and can be told apart based on
whether or not the unordered list contains a Fix or a Feat item.

All change blocks open with a mandatory Problem item. The optional items in a
change block are Test, Docs, and Note.

Syntax:

```md
- **Problem:** <problem-statement>
- **Fix:** <fix-statement>
- **Feat:** <feature-statement>
- **Test:** <test-statement>
- **Docs:** <docs-statement>
- **Note:** <note-statement>
```

## Specification

The key words MUST, MUST NOT, and MAY are to be read as described in
[RFC 2119][0].

### Changelogs

- a changelog's file name MUST end in `-$major.md`, where `$major` is the major
  version token and MUST only consist of characters in the range of
  `[A-Za-z0-9]`
- every level two heading in a changelog MUST be a changeset heading
- any content before the first changeset heading MUST NOT contain a level three
  or level four heading
- changesets MUST be sorted in descending chronological order of their `$date`,
  and changesets that share a `$date` MAY appear in any order
- each `csid` and each `link` label MUST be unique within the changelog

### Changesets

- a changeset heading MUST be a level two heading in the format of
  `[$date csid][link]`, where
  - `$date` MUST be a hyphen formatted date in the form of `YYYY-MM-DD`
  - `$date` MUST match the day that the changes are merged into `HEAD`
  - `csid` MUST only consist of four characters in the range of `[A-Z]`
  - `link` MUST be a reference label, such as the `csid`
- a changeset body MUST contain, in this order and separated by blank lines:
  1. a single alert block
  2. a summary statement
  3. the definition of `link`, which MUST be a HTTPS or file URL that links to
     a relevant resource
  4. a Fixes section, a Features section, or both, in that order
  5. a Changes section
- the alert block MUST be the breaking alert when the changeset contains a
  breaking change, and MUST NOT be the breaking alert when it does not

> [!NOTE]
> The blank line after an alert block is load bearing: without it, GFM reads
> the summary statement as part of the alert.

### Fixes and Features

- the Fixes, Features, and Changes headings MUST be level three headings, and
  MUST be the only level three headings
- the Fixes and Features body MUST ONLY contain a single unordered list, which
  MUST NOT be empty
- each list item MUST ONLY contain a single link in the form of
  `[description](#anchor)`, where `#anchor` is the anchor of a change in the
  same changeset
- Fixes items MUST link to a `fix`, and Features items MUST link to a `feat`
- each change MUST be linked to by exactly one list item

### Changes

- the Changes body MUST ONLY contain changes, and MUST contain at least one
- a change heading MUST be a level four heading in the format of
  `CSID type title`, where
  - `CSID` MUST exactly match the `csid` in the parent changeset heading
  - `type` MUST be either `fix` or `feat`
  - `type` MAY be prefixed by `breaking` and a space
  - `title` MUST only consist of words in the range of `[a-z0-9-]`, separated
    by single spaces
- a change heading MUST be unique within the changelog
- the anchor of a change is its heading, lowercased, with each space replaced by
  a hyphen, so `#### ABCD breaking fix exit code` is
  `#abcd-breaking-fix-exit-code`
- a change body MUST ONLY contain a single change block

### Change blocks

- a change block MUST be a single unordered list of items in the form of
  `- **Key:** statement`
- keys MUST appear in the order `Problem`, `Fix` or `Feat`, `Test`, `Docs`,
  `Note`, and each key MUST NOT appear more than once
- the `Problem` item MUST be present
- a `fix` MUST have a `Fix` item, and a `feat` MUST have a `Feat` item
- the `Test`, `Docs`, and `Note` items MAY be left out
- a statement that wraps onto more than one line MUST indent each continuation
  line by two spaces

> [!IMPORTANT]
> A `csid` may repeat letters which nets 456,976 unique combinations. Advancing
> a major version (e.g. `V3`, or `bubblegum`) starts the next changeling file.
> If the changelog starts to legitimately approach 457,000 changesets you've got
> bigger fish to fry than collision inside of a changelog.

[0]: https://www.rfc-editor.org/rfc/rfc2119
