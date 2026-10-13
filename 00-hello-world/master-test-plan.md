# Master Test Plan (MTP) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Implementation language | Objective-C with Foundation (GCC + GNUstep Base, Apple Clang + Foundation, Clang + libobjc2 + GNUstep Base) |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |
| Standard | Structure adapted from IEEE 829 / ISO/IEC/IEEE 29119-3 |

## 1. Introduction and scope

### 1.1 Objectives
"Tested enough" means: every acceptance criterion in SRS §4 is exercised by a unit test or a
black-box test, every CONV-13 diagnostic is checked byte-for-byte, the COUNT boundaries
0/1/1000/1001 are covered, and the public and hidden suites pass on Linux, macOS, Windows,
and in the container, with each of the three Objective-C toolchains.

### 1.2 In scope / out of scope
| In scope | Out of scope |
| :-- | :-- |
| Every FR/NFR in the SRS and the applicable CONV rules, on Linux, macOS, and Windows | Terminal rendering of non-ASCII names (a console concern) |
| The build contract targets (`make all … distclean`, `roundtrip`) | Performance on hardware other than CI runners and the development host |
| Windows UTF-16 → UTF-8 arguments and binary-mode output | Input, file, and path handling (the tool has none) |

## 2. Test items

| Item | Version / location |
| :-- | :-- |
| dp-hello | `00-hello-world/src/DPHello/` on branch `feat/00-hello-world` |
| Unit tests | `00-hello-world/src/Tests/` (38 tests) |
| Public black-box suite | `tests/public/` (10 tests) |
| Hidden black-box suite | `tests/private/` (10 tests, run by CI) |

## 3. Test levels and approach

| Level | Purpose | Technique(s) | Tooling | Owner |
| :-- | :-- | :-- | :-- | :-- |
| Unit | Scanner, validation, greeting, and diagnostics in isolation | Equivalence partitioning, boundary-value analysis, error guessing | Plain assertions with the runner in `src/Tests/DPHTestSupport.m` (`make test-unit`) | Developer |
| Integration | The pure core composing the units (`DPHApplicationTests.m`), and the output unit | End-to-end on `+[DPHApplication runWithArguments:count:]` outcomes; `tmpfile()` streams | `make test-unit` | Developer |
| System (black-box) | The specified CLI behavior, byte-exact | Specification-based | `make test` → `run-tests.py` | Developer |
| Acceptance | Hidden suite passes on all OSes | — | CI `make check` (`test-hidden`) | CI |
| Static analysis | Warnings, style | `-Wall -Werror` (with GNUstep's flags, which add `-Wall` too), `clang-format --dry-run --Werror` | `make lint` | Developer / CI |

## 4. Test design

### 4.1 Equivalence partitions and boundaries

| Input | Valid partitions | Invalid partitions | Boundaries |
| :-- | :-- | :-- | :-- |
| NAME | Non-empty: ASCII, spaces, punctuation, UTF-8, leading `-` | Empty | `""` vs one byte |
| COUNT | ASCII digits, value 1 … 1000, leading zeros | Empty, sign, space, non-digit, non-ASCII digit, 0, > 1000, overflow-sized | 0, 1, 1000, 1001; `000`, `0001000` |
| Option form | `-nX`, `-n X`, `--name=X`, `--name X`, `-c2` | Unknown short/long, abbreviation, missing value, flag with `=` | Last token without its value |
| Operands | None | Any word, `-`, anything after `--` | `--` alone (valid) |
| Scan order | `--help`/`--version` first, or after operands and bad values | A syntax error before them | Error vs. help in either order |

### 4.2 Additional test cases (beyond the supplied suite)

| ID | Requirement(s) | Preconditions | Steps / command | Expected result | Level |
| :-- | :-- | :-- | :-- | :-- | :-- |
| T-01 | FR-04, FR-05 | — | `testCountBoundaries` | 0 and 1001 rejected; 1 and 1000 accepted | unit |
| T-02 | FR-04 | — | `testCountLeadingZeros` | `007` → 7, `0001000` → 1000, `000` rejected | unit |
| T-03 | FR-05 | — | `testCountRejectsNonDigits`, `testCountDoesNotOverflow` | `+1`, ` 1`, `1e3`, Arabic-Indic digit, 32 digits rejected | unit |
| T-04 | FR-03 | — | `testEmptyNameRejected` | `invalid argument '' for '--name'` / `'-n'` | unit |
| T-05 | FR-06 | — | `testOnlyTheWinningValueIsValidated` | `-n '' -c 0 -n B --count=2` greets B twice | unit |
| T-06 | FR-02 | — | `testValuesMayStartWithDash` | `--name -x`, `-n-x`, `-n --help` take the value | unit |
| T-07 | CONV-12 | — | `testHelpAndVersionStopTheScan`, `testSyntaxErrorBeforeHelpWins`, `testOperandAndValueErrorsDoNotBeatHelp` | `--help extra -x`, `extra --help`, `--count 0 --help` → help; `-x --help` → error | unit |
| T-08 | FR-10, CONV-08 | — | `testUnknownOptions` | `--nam`, `--nme=Ada`, `--names`, `--=x` unrecognized, quoted whole; `-ë` quoted as one character | unit |
| T-09 | FR-10 | — | `testMissingValues`, `testFlagsRejectValues` | Exact CONV-13 kinds and subjects | unit |
| T-10 | FR-09, CONV-09 | — | `testTerminatorMakesEverythingAnOperand`, `testOperandsAreRejectedAfterTheScan` | `-- -n`, `-- --help`, `-` → extra operand; `--` alone accepted | unit |
| T-11 | FR-11 | — | `testUsageErrorsWriteNoOutput`, `testDeliverWritesBothStreams` | Empty stdout and the exact diagnostic for every error class | unit |
| T-12 | CONV-25 | POSIX shell (container) | `dp-hello -c 1000 \| head -1`; `dp-hello -c 1000 > /dev/full` | One line, no diagnostic; status 1 on a full device | system |
| T-13 | NFR-01, CONV-05 | Windows CI | Public and hidden suites (UTF-8 names) on windows-latest | All pass, LF only | system |

### 4.3 Negative and robustness testing
All invalid option forms, values, and operands are unit-tested (T-03 … T-11) with exact
diagnostics. Robustness (NFR-03, CONV-24): the unit tests and the executable were also built
in the container with `-O1 -g -fsanitize=address,undefined -fno-sanitize-recover` and run on
edge invocations (no arguments, `-`, `--`, `-n`, `--name=`, a 20-digit count, `-` followed by
a lone `0xFF` byte, `--=`, `-c2 -nKen`, `extra --help`, T-12): no sanitizer reports and no
leaks outside the Objective-C runtime's own class tables. The code raises no exceptions and
writes with stdio, so a closed pipe cannot produce an uncaught `NSException`. Input-file cases
do not apply (no input is read).

### 4.4 Performance and resource testing
NFR-02, measured in the container (Debian trixie, GCC 14 + GNUstep Base) on the development
host: 20 runs of `build/bin/dp-hello -c 1000` from Python's `subprocess` took 19 ms on
average, with a peak RSS (`getrusage(RUSAGE_CHILDREN).ru_maxrss`) of 15.2 MiB, almost all of
it the GNUstep Base library being loaded. Both are within 100 ms and 32 MiB; as a native
build, the limit applies without a runtime baseline (CONV-31). Output is at most
1000 × (len(NAME) + 9) bytes, so memory does not grow with anything but NAME and COUNT.

## 5. Test environments

| Environment | OS / version | Toolchain | How provisioned |
| :-- | :-- | :-- | :-- |
| Container | Debian trixie (`debian:trixie-slim`) | GCC 14 (gobjc) + GNUstep Base, clang-format 19.1.7, Python 3.13 | `Containerfile` (podman) |
| CI, Linux | ubuntu-latest | GCC (gobjc) + GNUstep Base (apt); clang-format 19.1.7 (PyPI) | `.github/workflows/ci.yml` (`native` job) |
| CI, macOS | macos-latest | Apple Clang + Foundation; clang-format 19.1.7 (PyPI) | `.github/workflows/ci.yml` |
| CI, Windows | windows-latest | MSYS2 CLANG64: Clang + libobjc2 + GNUstep Base; clang-format 19.1.7 (PyPI) | `.github/workflows/ci.yml` (msys2/setup-msys2) |

## 6. Entry and exit criteria

- **Entry:** HLD and LLD complete; `make all` succeeds; `make lint` is clean.
- **Exit:** all unit tests, the public and hidden suites pass in the container and on all three
  OSes; `make roundtrip` passes natively; no open severity 1–2 defects; every RTM row Verified.
- **Suspension / resumption:** suspend on a build or toolchain failure on any platform; resume
  once the toolchain step is fixed and the full CI matrix is re-run.

## 7. Defect management
Defects are GitHub issues in `dialectic-playground/objc` with the failing command, platform,
toolchain, and expected vs. actual bytes. A fix is re-tested on the full CI matrix, and every
fixed defect gets a unit test that fails without the fix.

| Severity | Definition |
| :-- | :-- |
| 1 — Critical | Crash, or wrong output on a mainline path |
| 2 — Major | Wrong diagnostic text or exit status; platform-specific byte difference |
| 3 — Minor | Style, documentation, or lint findings with no behavioral effect |

## 8. Schedule and deliverables

| Milestone | Deliverable | Target date |
| :-- | :-- | :-- |
| Design complete | `hld.md`, `lld.md` | 2026-10-13 |
| Implementation complete | `src/`, unit tests, `Makefile` hooks | 2026-10-13 |
| Verification complete | RTM all Verified, CI green | 2026-10-13 |

## 9. Risks and contingencies

| Risk | Mitigation |
| :-- | :-- |
| Windows-only failure (CRLF, ANSI-codepage arguments) | Binary streams and `wmain`; CI on Windows for every push |
| Syntax accepted by Clang but not by GCC's Objective-C | MRC and plain message sends only; the container and Linux CI build with GCC, macOS and Windows with Clang |
| clang-format version drift (MSYS2's clang ships its own, newer clang-format) | clang-format 19.1.7 on every platform (container package, PyPI natively, PyPI first on PATH in MSYS2); `make toolchain` fails on any other version |

## 10. Test summary (complete at the end)

| Metric | Value |
| :-- | :-- |
| Unit tests (pass / total) | 38 / 38 (237 assertions), on all four environments |
| Coverage (lines, unit tests, gcov in the container) | 100 % of `DPHCommandLine.m`, `DPHValidation.m`, `DPHGreeting.m`, `DPHUsageError.m`, `DPHApplication.m`; `DPHOutput.m` 89 % (the stdout-failure return: T-12); `DPHPlatform.m` and `main.m` are exercised by the black-box suites |
| Public black-box (pass / 10) | 10 / 10 (container, Linux, macOS, Windows) |
| Hidden black-box (pass / 10, from CI) | 10 / 10 |
| Open defects by severity | 0 / 0 / 0 |
