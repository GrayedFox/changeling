# CHANGELOG-bubblegum

Changes only started to be recorded on the 17/11/2026 and on the bubblegum
branch.

The project has a much richer history that can be gleaned from VCS but for a
human-readable summary of changes from the 17th onwards, start here.

## [2026-11-18 WXYZ][WXYZ]

> [!CAUTION]
> BREAKING CHANGES

A missing unit now exits with the same code as in systemd, and `is-active` can
print JSON for scripts. The exit code change breaks scripts that checked for 1.

[WXYZ]: https://github.com/grayedfox/changeling/commit/example2

### Fixes

- [A missing unit exited 1 instead of 5](#wxyz-breaking-fix-missing-unit-exit-code)

### Features

- [is-active --json prints the status of each unit as JSON](#wxyz-feat-json-status)

### Changes

#### WXYZ breaking fix missing unit exit code

- **Problem:** `start`, `stop`, and `restart` exited 1 for a unit that does not
  exist, while systemd exits 5, so a script could not tell a missing unit from a
  failed one.
- **Fix:** A missing unit exits 5 in every command.
- **Test:** `test_1316_missing_unit_exits_5`
- **Note:** Scripts that checked for exit code 1 must check for 5.

#### WXYZ feat json status

- **Problem:** Scripts had to parse the text output of `is-active` to read the
  status of several units.
- **Feat:** `is-active --json` prints one JSON object per unit, with its name
  and status.
- **Test:** `test_1317_is_active_json`
- **Docs:** The `is-active` section of the man page describes `--json`.

## [2026-11-17 ABCD][ABCD]

> [!WARNING]
> MAJOR CHANGES

Bug fixes that mostly target crashes and hangs, plus some extras that focus on
container hardening and performance improvements. Each bug in the scripts comes
with a new test that failed before its fix, and the PID 1 bugs were reproduced
with the script running as PID 1 in a container. The fixes keep PID 1 alive and
stopping all units when one unit is bad, stop forked children from running the
parent's code, parse unit settings the way systemd does, only trust notify
messages from the service's own user, and make parallel calls safe. This entry
also introduces the changelog and its spec.

[ABCD]: https://github.com/grayedfox/changeling/commit/example

### Fixes

- [Starting two instances of one template started only the last one, twice](#abcd-fix-template-instances)
- [A child process that failed before exec ran the parent's code](#abcd-fix-forked-child-escape)
- [Timeouts like 1h, 90sec or 0 were read as 1 or 0 seconds](#abcd-fix-timeout-parsing)
- [One bad unit killed PID 1 at boot or skipped the rest of shutdown](#abcd-fix-one-bad-unit)
- [Socket units held their port, so their own service could not bind it](#abcd-fix-socket-port)
- [enable --force crashed and could delete a file in the current folder](#abcd-fix-enable-force)
- [After systemctl halt, PID 1 ignored docker stop or froze its init loop](#abcd-fix-halt-then-stop)
- [An environment value with a quote crashed the start](#abcd-fix-env-value-quote)
- [KillSignal=TERM or a signal number crashed the stop](#abcd-fix-kill-signal-names)
- [WorkingDirectory=~ made the service fail](#abcd-fix-workingdirectory-home)
- [Units with drop-in files were parsed on every load, with a wrong path](#abcd-fix-drop-in-cache)
- [A backslash line continuation glued two words together](#abcd-fix-line-continuation)
- [The boolean value on was read as false](#abcd-fix-boolean-on)
- [Two parallel calls could fail to create the same folder](#abcd-fix-makedirs-race)
- [The listen thread never released its lock, so the init loop stopped](#abcd-fix-listen-lock)
- [A parallel is-active could read an empty status file and say inactive](#abcd-fix-atomic-status-file)
- [Stopping a service scanned all processes 100 times](#abcd-fix-pidlist-scan)
- [Any local user could send MAINPID=1 to a notify socket](#abcd-fix-notify-trust)
- [Notify messages were read one per second](#abcd-fix-notify-batching)
- [disable of an init.d service crashed without rc3.d and rc5.d folders](#abcd-fix-sysv-disable)
- [A successful ExecStop that did not end the service left it running](#abcd-fix-execstop-kill-fallback)
- [list-dependencies showed PartOf= by chance and BindsTo= without a label](#abcd-fix-list-dependencies)
- [Every %x in a unit line rebuilt all specifier values](#abcd-fix-expand-special-once)
- [Importing journalctl3 ran its main function and exited](#abcd-fix-journalctl3-import)
- [PID 1 exited with code 1 after a clean docker stop](#abcd-fix-pid1-exit-code)
- [The unit test workflow passed even when tests failed](#abcd-fix-ci-test-failures)
- [Twenty copies of the unit matching code are now one helper](#abcd-fix-match-units-helper)
- [Unused and broken helpers were removed](#abcd-fix-dead-code)

### Features

- [A human-readable changelog with a written spec](#abcd-feat-changelog)

### Changes

#### ABCD fix template instances

- **Problem:** All instances of a template unit (`web@.service`) shared one
  cached config, and loading an instance renamed it.
  `systemctl start web@a web@b` exited 0, but only `web@b` ran, twice. Stop and
  boot had the same bug.
- **Fix:** Each instance gets its own copy of the config, with its own name and
  status.
- **Test:** `test_29201_start_two_template_instances`

#### ABCD fix forked child escape

- **Problem:** A forked child that failed before or during `execve` (an unknown
  `User=`, a missing binary) unwound into the parent's code. It released the
  parent's per-unit lock. In PID 1 it became a second init loop and was recorded
  as the service's main PID, so the service looked active.
- **Fix:** The child always exits inside `execve_from`, and a unit lock is only
  released by the process that took it.
- **Test:** `test_1307_failed_child_never_returns_to_caller`,
  `test_1308_failed_child_keeps_the_parent_lock`,
  `test_39101_pid1_failed_exec_starts_no_second_init`

#### ABCD fix timeout parsing

- **Problem:** `1h`, `90sec` and `1.5s` were all read as 1 second. `0`, which
  means "no timeout" in systemd, was read as 0, so `stop` sent SIGKILL at once.
- **Fix:** Time spans are parsed with the systemd units (us, ms, s, min, h, d),
  decimals and sums like `1h 30min`. `TimeoutStartSec=0` and `TimeoutStopSec=0`
  mean no timeout.
- **Test:** `test_1301_time_to_seconds_units`,
  `test_1302_timeout_zero_means_no_timeout`

#### ABCD fix one bad unit

- **Problem:** There was no error guard per unit. One unit that raised an
  exception at boot killed PID 1, so the container exited. On `docker stop`, the
  units after it were never stopped.
- **Fix:** `start_unit` and `stop_unit` log the error and go on with the next
  unit.
- **Test:** `test_1309_one_failing_unit_does_not_stop_the_others`,
  `test_39102_pid1_survives_bad_unit_at_boot`,
  `test_39103_pid1_stops_all_units_on_docker_stop`

#### ABCD fix socket port

- **Problem:** Starting `foo.socket` bound its port and kept it open while
  `foo.service` started, so the service failed with "Address already in use".
- **Fix:** The socket is only bound in the `TESTING_LISTEN` test mode, which is
  the only code that uses it.
- **Test:** `test_29203_socket_unit_leaves_port_to_service`

#### ABCD fix enable force

- **Problem:** `enable --force` on an enabled unit removed `multi-user.target`
  relative to the current folder instead of the old symlink. It crashed, or
  deleted a file of that name.
- **Fix:** It removes the symlink.
- **Test:** `test_29202_enable_force_on_enabled_unit`

#### ABCD fix halt then stop

- **Problem:** After `systemctl halt` (SIGQUIT), PID 1 ignored SIGTERM, so
  `docker stop` waited for its timeout and then used SIGKILL. A SIGQUIT during a
  unit restart froze the init loop on its own lock.
- **Fix:** The SIGQUIT handler only sets the "exit when no processes are left"
  flag.
- **Test:** `test_39104_pid1_halt_then_docker_stop`,
  `test_39105_pid1_sigquit_keeps_init_loop_running`

#### ABCD fix env value quote

- **Problem:** With `Environment=OPTS=it's`, `ExecStart=/bin/foo $OPTS` crashed
  with "No closing quotation".
- **Fix:** When a quote inside a value breaks the split, the line is split first
  and the values are expanded after, so a quote in a value stays a plain
  character.
- **Test:** `test_1305_env_value_with_quote`

#### ABCD fix kill signal names

- **Problem:** `KillSignal=TERM` and `KillSignal=15` are valid in systemd, but
  crashed `stop` with an AttributeError.
- **Fix:** Names without the `SIG` prefix and signal numbers are accepted. An
  unknown name falls back to SIGTERM with a warning.
- **Test:** `test_29204_kill_signal_without_sig_prefix`

#### ABCD fix workingdirectory home

- **Problem:** `WorkingDirectory=~` was not expanded, so the start failed with
  "bad workingdir".
- **Fix:** `~` is the home folder of the service user.
- **Test:** `test_29205_working_directory_home`

#### ABCD fix drop in cache

- **Problem:** For a unit with drop-in files (`foo.service.d/*.conf`), the cache
  key and the unit path became the last drop-in file. The unit was parsed again
  on every load, and `--user` checks looked at the wrong path.
- **Fix:** The drop-in loop no longer overwrites the unit path.
- **Test:** `test_1306_drop_in_conf_is_loaded_once`

#### ABCD fix line continuation

- **Problem:** A backslash at the end of a line was removed without a space, so
  `--a=1\` followed by `--b=2` became one argument, `--a=1--b=2`.
- **Fix:** A continued line is joined with a space, as in systemd.
- **Test:** `test_1304_line_continuation_keeps_words_apart`

#### ABCD fix boolean on

- **Problem:** Booleans were decided by their first character, so `on` was
  false.
- **Fix:** `1`, `yes`, `y`, `true`, `t` and `on` are true, in any case.
- **Test:** `test_1303_getbool_accepts_on`

#### ABCD fix makedirs race

- **Problem:** The code checked if a folder existed and then created it. Two
  parallel calls could both pass the check, and the second one failed with
  FileExistsError.
- **Fix:** One `makedirs_ok` helper replaces all 18 calls and accepts a folder
  that another process just created.
- **Test:** `test_1310_parallel_mkdir_is_not_an_error`

#### ABCD fix listen lock

- **Problem:** The socket listen thread (test mode only) took the init loop lock
  and never released it. Only the first request got an answer, and the init loop
  stopped reaping and restarting.
- **Fix:** The thread releases the lock after each connection.
- **Test:** `test_39106_pid1_listen_answers_every_request`

#### ABCD fix atomic status file

- **Problem:** A status file was emptied and then written again. A parallel
  `is-active` could read it empty and answer "inactive" for a running unit.
- **Fix:** The status file is written to a temporary file and renamed into
  place.
- **Test:** `test_1311_status_file_is_never_seen_empty`

#### ABCD fix pidlist scan

- **Problem:** To find a service's child processes, `pidlist_of` scanned `/proc`
  100 times, even when nothing new was found.
- **Fix:** It stops as soon as a scan finds no new process.
- **Test:** `test_1312_pidlist_of_stops_when_done`

#### ABCD fix notify trust

- **Problem:** The notify socket of a `Type=notify` service is writable for all
  users. Any local user could send `READY=1` and `MAINPID=1` while the service
  started, and a later `stop` sent its signals to PID 1.
- **Fix:** The kernel now names the sender of each message. Messages from root,
  or from the user that runs systemctl, are accepted. A message from another
  user is only accepted when that user runs the service's main process and every
  `MAINPID=` it names.
- **Test:** `test_39107_notify_socket_ignores_other_processes`

#### ABCD fix notify batching

- **Problem:** The notify socket was read one message per loop round, with a one
  second sleep in between. A service that sent several `STATUS=` messages before
  `READY=1` was seen as ready seconds late.
- **Fix:** Each round reads all messages that are already waiting.
- **Test:** `test_1313_notify_reads_all_waiting_messages`

#### ABCD fix sysv disable

- **Problem:** `disable` of an `/etc/init.d` service listed the rc3.d and rc5.d
  folders without checking that they exist, and crashed when they did not.
- **Fix:** A missing rc folder means nothing is enabled there.
- **Test:** `test_29206_disable_sysv_without_rc_folders`

#### ABCD fix execstop kill fallback

- **Problem:** When `ExecStop=` ran without error but did not end a `simple` or
  `forking` service, `stop` waited for the timeout, said OK, and left the
  process running.
- **Fix:** After the wait, the service is killed as if it had no `ExecStop=`:
  `KillSignal=` first, then SIGKILL after `TimeoutStopSec=`. A failing
  `ExecStop=` still leaves the service running and makes `stop` fail, as before.
- **Test:** `test_29207_stop_kills_what_execstop_left`

#### ABCD fix list dependencies

- **Problem:** The filter list of `list-dependencies` was replaced inside its
  own loop, so `PartOf=` units were shown only when another dependency came
  first. `BindsTo=` units had no label because of a typo (`Bindsto`).
- **Fix:** One filter list for the whole loop (start dependencies only, like
  systemd), and the label key is spelled `BindsTo`.
- **Test:** `test_29208_list_dependencies_shows_start_dependencies`

#### ABCD fix expand special once

- **Problem:** Every `%x` specifier in a line rebuilt the values of all
  specifiers, including user and group lookups.
- **Fix:** The values are built once per line, and not at all for a line without
  `%`.
- **Test:** `test_1314_expand_special_looks_up_once`

#### ABCD fix journalctl3 import

- **Problem:** `journalctl3.py` called `sys.exit(main())` at module level, so
  importing it parsed the importer's command line and exited.
- **Fix:** `main()` only runs when the file is run as a script. The
  `journalctl3` entry point still calls `main()`.
- **Test:** `test_1315_journalctl3_can_be_imported`

#### ABCD fix pid1 exit code

- **Problem:** When no unit needed a restart, the init loop set the error flag,
  so PID 1 exited with code 1 after a clean `docker stop`.
- **Fix:** Nothing to restart is not an error.
- **Test:** `test_39108_pid1_exit_code_zero_after_docker_stop`

#### ABCD fix ci test failures

- **Problem:** The unit test workflow ran `make tests ... || true`, so the job
  passed even when tests failed or the test run crashed before writing results.
- **Fix:** The `|| true` is gone, and the steps that find and publish the test
  results run with `if: always()`, so results are still published when tests
  fail.
- **Test:** None, the workflow only runs on GitHub.

#### ABCD fix match units helper

- **Problem:** Twenty commands had a copy of the same code to match unit names
  and report missing ones. Every fix had to be made in all copies.
- **Fix:** One `match_modules` helper. Each command keeps its own error code for
  a missing unit.
- **Test:** The existing test suite.

#### ABCD fix dead code

- **Problem:** Several helpers were never called, and two were broken:
  `unit_name_escape` turned `foo-bar` into `foo/bar`, and `Systemctl.echo`
  joined its arguments wrongly.
- **Fix:** Removed `unit_name_escape`, `Systemctl.echo`, `get_SocketTimeoutSec`,
  `get_start_dependencies`, `DefaultTimeoutAbortSec` and a list that was built
  and thrown away.
- **Test:** The existing test suite.

#### ABCD feat changelog

- **Problem:** The project history could only be read from VCS, which is not a
  human-readable summary of changes.
- **Feat:** `CHANGELOG-SPEC.md` defines the format of this file: one changeset
  per merge, named by its date and a four letter csid, with an alert, a summary,
  and linked lists of fixes and features. `CHANGELOG-bubblegum.md` holds the
  changesets from 2026-11-17 onwards.
