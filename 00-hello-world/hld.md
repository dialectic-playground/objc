# High-Level Design (HLD) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Implementation language | Objective-C with Foundation (GCC + GNUstep Base, Apple Clang + Foundation, Clang + libobjc2 + GNUstep Base) |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |
| Status | Approved |
| Inputs | `specs/URD.md`, `specs/SRS.md`, `specs/user-manual.md`, `shared/CLI-CONVENTIONS.md` |

## 1. Introduction

### 1.1 Scope
`dp-hello` writes `Hello, ` + NAME + `!` + LF to standard output COUNT times (NAME defaults to
`World`, COUNT to 1, range 1–1000), prints help and version text, and reports usage errors
with the exact CONV-13/14 diagnostics and exit status 2. As the SRS scope states, it reads no
input, takes no operands, and touches no files; it also reads no environment variables and
starts no processes (NFR-07).

### 1.2 Definitions and acronyms
| Term | Meaning |
| :-- | :-- |
| Scan | The left-to-right pass over the arguments (CONV-12) |
| Winning value | The last occurrence of `--name` or `--count` (CONV-11) |
| Usage error | Any CONV-13 condition; exit status 2 |
| Outcome | The bytes for stdout and stderr plus the exit status that one run produces |
| MRC | Manual reference counting (`retain`/`release`/`autorelease`), as opposed to ARC |
| GNUstep Base | The Foundation implementation used on Linux and Windows |

### 1.3 References
- SRS §3 (interfaces), §4 (FR-01 … FR-11), §5 (NFR-01 … NFR-07), §6 (diagnostics)
- CLI-CONV §2 (CONV-03, CONV-05), §3 (CONV-07 … CONV-12), §4 (CONV-13 … CONV-15), §8

## 2. Requirements summary

| Area | SRS requirements | Architectural impact |
| :-- | :-- | :-- |
| Option scanning | FR-02, FR-06, FR-07, FR-08, FR-09, FR-10, CONV-07 … CONV-12 | A hand-written scanner (`DPHCommandLine`) that stops at `--help`, `--version`, or the first syntax error |
| Value validation | FR-03, FR-04, FR-05, FR-06 | A separate `DPHValidation` unit that checks only the winning values, after the scan |
| Greeting | FR-01, FR-02, FR-04, NFR-05 | A pure class method (`DPHGreeting`) |
| Diagnostics | FR-03, FR-05, FR-09, FR-10, FR-11, CONV-13 … CONV-15 | One error class with one formatter (`DPHUsageError`) |
| Program flow | FR-07, FR-08, FR-11, §3.7 | A pure core (`DPHApplication`) that returns an outcome instead of writing |
| Output | CONV-03, CONV-25 | One writer (`DPHOutput`) for both standard streams |
| Portability | NFR-01, CONV-03, CONV-05 | A `DPHPlatform` unit isolates Windows (binary streams, UTF-16 → UTF-8 arguments) |

## 3. Architectural overview

### 3.1 Context diagram

```text
   argv (UTF-8 bytes; UTF-16 on Windows) ──▶ ┌──────────┐ ──▶ stdout (greetings, help, version)
                                              │ dp-hello │ ──▶ stderr (usage diagnostics)
                                              └──────────┘ ──▶ exit status 0 / 2
   no stdin, files, environment, or child processes (NFR-07, CONV-26)
```

### 3.2 Component (module) decomposition

| Component | Responsibility | Depends on |
| :-- | :-- | :-- |
| `main` | Entry point; autorelease pool; obtains UTF-8 arguments, runs, delivers the outcome | `DPHPlatform`, `DPHApplication`, `DPHOutput` |
| `DPHPlatform` | Windows binary mode and UTF-16 → UTF-8 conversion; no-op on POSIX | Win32 API, CRT, Foundation |
| `DPHApplication` | Runs scan → validate → greet and returns a `DPHOutcome`; owns the help and version texts | `DPHCommandLine`, `DPHValidation`, `DPHGreeting`, `DPHUsageError` |
| `DPHCommandLine` | Turns arguments into raw winning values, a help/version action, or a usage error | `DPHUsageError` |
| `DPHValidation` | Checks NAME and COUNT, applies defaults, produces a `DPHGreetingRequest` | `DPHCommandLine`, `DPHUsageError` |
| `DPHGreeting` | Builds one greeting line (pure) | Foundation (`NSData`) |
| `DPHUsageError` | The usage-error class and the exact diagnostic bytes | `DPHProgram` |
| `DPHOutput` | Writes an outcome's bytes to stdout and stderr; reports write failures | C stdio |
| `DPHProgram` | Canonical name, version, and exit-status constants | — |

### 3.3 Data flow
`main` creates an `NSAutoreleasePool`, switches the streams to binary (Windows), converts the
command line to UTF-8 (Windows), and calls `+[DPHApplication runWithArguments:count:]` with the
arguments after the program name. `+[DPHCommandLine parseArguments:count:]` scans them and
returns a `DPHParsedArguments`. For help or version, the application returns the fixed text.
For a usage error it returns the diagnostic as stderr bytes with status 2 (an operand is
reported only after the whole scan, so `--help` anywhere wins). Otherwise
`+[DPHValidation requestFromArguments:error:]` produces a `DPHGreetingRequest` or a usage
error; the application builds the line once with `+[DPHGreeting lineForName:]` and appends it
COUNT times. Finally `+[DPHOutput deliverOutcome:output:error:]` writes the bytes and returns
the exit status (0, 2, or 1 if stdout could not be written), and the pool is drained.

## 4. Key design decisions

| # | Decision | Alternatives considered | Rationale |
| :-- | :-- | :-- | :-- |
| D1 | Validate values after the scan | Validate each occurrence while scanning | FR-06: only the winning value is validated; `-c 0 -c 2` is valid |
| D2 | The scan stops at the first `--help`, `--version`, or option syntax error; operands are only collected and rejected after the scan | Reject an operand as soon as it is reached | CONV-12 (curriculum v1.4.0): only syntax errors compete with `--help`/`--version`, so `extra --help` prints the help |
| D3 | A pure core returns an outcome (stdout bytes, stderr bytes, status); one writer performs I/O | Write from each unit | Error atomicity (FR-11) by construction; end-to-end unit tests without capturing streams |
| D4 | Arguments stay C strings; output is built as `NSData` | Convert to `NSString` | Bytes are echoed exactly (CONV-05) even when they are not valid UTF-8; no encoding round trip |
| D5 | Plain MRC Objective-C with `NSAutoreleasePool`, no ARC, `@autoreleasepool`, or `@[]`/`@{}`/`@()` literals | ARC and modern syntax | GCC's Objective-C front end (container and Linux) supports none of them; one source builds with GCC and Clang |
| D6 | No getopt and no Foundation argument parsing (`NSProcessInfo`, `NSUserDefaults`) | `getopt_long`, `NSUserDefaults` | Not portable in the same form, permutes arguments, uses `argv[0]` (CONV-01) or reads defaults domains (NFR-07) |
| D7 | Windows enters through `wmain` (`-municode`) | `GetCommandLineW` + `CommandLineToArgvW` | The CRT's own command-line splitting; one conversion function |
| D8 | stdio `fwrite` for output | `NSFileHandle` | `NSFileHandle` raises an exception on a closed pipe (CONV-24); stdio reports a status |

## 5. Cross-platform strategy
All OS-specific code is in `DPHPlatform.m` (and the `main`/`wmain` choice in `main.m`), behind
`#ifdef _WIN32`. On Windows, `DPHPlatformUseBinaryStreams` puts stdout and stderr in
`_O_BINARY` mode, so every LF the tool writes stays a single `0x0A` (CONV-03), and
`DPHPlatformUTF8Arguments` converts the UTF-16 arguments to UTF-8 with
`WideCharToMultiByte(CP_UTF8, …)` (CONV-05), so `Zoë` is the same bytes as on Linux and macOS.
On POSIX, arguments are already bytes and are used as UTF-8 unchanged. All text is ASCII
literals plus the user's bytes; nothing is locale-dependent (CONV-06). No paths are used
(CONV-19 … CONV-21 do not apply). The compiler and Foundation differ by OS (GCC + GNUstep
Base, Apple Clang + Foundation, Clang + libobjc2 + GNUstep Base in MSYS2 CLANG64); the
project `Makefile` selects them as the root `Makefile` does, and the code uses only the
Objective-C subset that all three accept.

## 6. Error handling and diagnostics
`DPHCommandLine` and `DPHValidation` report problems as a `DPHUsageError` (kind, subject
bytes, option as written). Exactly one method, `-[DPHUsageError diagnostic]`, maps each kind to
its CONV-13 message and appends the CONV-14 line; exactly one place,
`+[DPHApplication runWithArguments:count:]`, maps results to exit statuses (0 success, 2 usage
error), and `+[DPHOutput deliverOutcome:output:error:]` substitutes 1 when stdout cannot be
written. Usage errors are always detected before anything is written (FR-11). No exceptions
are raised or caught; there are no other error paths.

## 7. Non-functional design

| Quality attribute | SRS reference | How the design achieves it |
| :-- | :-- | :-- |
| Performance / memory | NFR-02, CONV-31 | Native executable (the memory limit applies as is, CONV-31); one pass over the arguments; output of at most 1000 × (NAME + 9) bytes built in memory |
| Portability | NFR-01 | `DPHPlatform` unit; LF-only literals; binary streams on Windows; the GCC/Clang common subset of Objective-C |
| Robustness | NFR-03 | Bounds-checked scanning, saturating COUNT parser, no exceptions; write failures end output quietly |
| Security / input validation | NFR-07, FR-03, FR-05 | Reads only argv; values are copied as bytes, never used as format strings |
| Maintainability | NFR-04 | Separate `DPHCommandLine`, `DPHValidation`, `DPHGreeting`, and `DPHOutput` units (one responsibility each) |
| Testability | NFR-05 | `+[DPHGreeting lineForName:]` and the whole application core are pure and unit-tested |

## 8. Risks and open issues

| Risk / issue | Likelihood | Impact | Mitigation |
| :-- | :-- | :-- | :-- |
| Windows CRT translates LF to CRLF | M | H | `_setmode(_O_BINARY)` on both streams; black-box suites on Windows CI |
| Non-ASCII arguments mangled by the ANSI code page on Windows | M | H | `wmain` + UTF-8 conversion |
| Code that Clang accepts but GCC's Objective-C does not (or the reverse) | M | M | MRC only, no modern syntax, `-std=gnu11`; `-Werror` lint on all three OSes and in the container |
| GNUstep headers warn under stricter flags (`-Wextra`) | H | L | Lint uses `-Wall -Werror` (plus GNUstep's own flags) |
| clang-format versions differ between container and runners | M | L | clang-format 19.1.7 everywhere (Debian package in the container, PyPI natively); `make toolchain` enforces it |
| SIGPIPE terminates the process on a closed pipe | L | L | Allowed by CONV-25 (status unspecified) |

## 9. Approval

| Role | Name | Date | Decision |
| :-- | :-- | :-- | :-- |
| Author | Brandon Perkins | 2026-10-13 | Submitted |
| Reviewer | CI (container, Linux, macOS, Windows) | 2026-10-13 | Approved when all checks pass |
