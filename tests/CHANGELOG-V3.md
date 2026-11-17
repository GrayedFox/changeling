# CHANGELOG-V3

## [2026-11-18 ZOOM][pr-214]

> [!WARNING]
> MAJOR CHANGES

Collections can now be exported in a format that every major browser can
import.

[pr-214]: https://git.example.com/shelf/pulls/214

### Features

- [Export a collection as a browser bookmarks file](#zoom-feat-browser-export)

### Changes

#### ZOOM feat browser export

- **Problem:** Collections could only be exported as JSON, which no browser can
  import.
- **Feat:** Export now offers a bookmarks file that Firefox, Chrome, Safari, and
  Edge can import.
- **Docs:** The Export section of the user guide covers the new format.

## [2026-11-18 BEEP][pr-213]

> [!NOTE]
> STANDARD CHANGES

Two small fixes to reminders.

[pr-213]: https://git.example.com/shelf/pulls/213

### Fixes

- [Reminders played their sound twice](#beep-fix-double-chime)
- [Snoozed reminders came back at midnight UTC](#beep-fix-snooze-time-zone)

### Changes

#### BEEP fix double chime

- **Problem:** A reminder played its sound twice when the app was open in more
  than one tab.
- **Fix:** Only the most recently used tab plays the sound.

#### BEEP fix snooze time zone

- **Problem:** Snoozing a reminder "until tomorrow" brought it back at midnight
  UTC instead of 09:00 in your own time zone.
- **Fix:** Snoozed reminders come back at 09:00 in the time zone set in your
  profile.
- **Note:** Reminders snoozed before this release keep their old time.

## [2026-11-12 TIDE][audit-2026-11]

> [!CAUTION]
> BREAKING CHANGES

The November security review found that shared collections stayed public
forever. Share links now expire, and owners choose how long they last.

[audit-2026-11]: file:///srv/shelf/audits/2026-11-security-review.pdf

### Fixes

- [Share links never expired](#tide-breaking-fix-share-link-expiry)

### Features

- [Owners choose how long a share link lasts](#tide-feat-share-link-lifetime)

### Changes

#### TIDE breaking fix share link expiry

- **Problem:** A share link never expired, so anyone who ever held one could
  read the collection, even after it was no longer meant to be public.
- **Fix:** Share links expire after 30 days. Links made before this release
  expire on 2026-12-12.
- **Docs:** The Sharing section of the user guide explains expiry.
- **Note:** Re-share any collection that must stay public after 2026-12-12.

#### TIDE feat share link lifetime

- **Problem:** Owners could not choose how long a share link should last.
- **Feat:** Owners can set a share link to last from 1 to 365 days.
- **Docs:** The Sharing section of the user guide explains the setting.
