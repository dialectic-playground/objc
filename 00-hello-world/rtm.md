# Requirements Traceability Matrix (RTM) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |

Code paths are relative to `src/DPHello/`; unit tests live in `src/Tests/`. Public black-box
tests are P01 … P10. The hidden suite runs in CI on Linux, macOS, and Windows and is not cited.

## 1. User requirements to system requirements

| User requirement (URD) | Derived system requirements (SRS) |
| :-- | :-- |
| UR-01 | FR-01 |
| UR-02 | FR-02 |
| UR-03 | FR-04 |
| UR-04 | FR-07 |
| UR-05 | FR-08 |
| UR-06 | FR-03, FR-05, FR-09, FR-10, FR-11 |
| UR-07 | FR-01, SRS §3.7 |
| UR-08 | NFR-01, CONV-03 |
| UR-09 | FR-02, CONV-05 |
| UR-10 | FR-06, FR-10, CONV-07 … CONV-15 |
| UR-11 | NFR-02 |
| UR-12 | NFR-06 |

## 2. Forward traceability

| Req. ID | Summary | Design (HLD/LLD) | Code (file::function) | Verification (unit / black-box) | Status |
| :-- | :-- | :-- | :-- | :-- | :-- |
| UR-01 | Classic greeting | HLD §3.3 | see FR-01 | P01 | Verified |
| UR-02 | Choose the name | HLD §3.2 | see FR-02 | P02, P03, P04 | Verified |
| UR-03 | Repeat the greeting | HLD §3.2 | see FR-04 | P05, P06 | Verified |
| UR-04 | Help screen | HLD §3.2 | see FR-07 | P07 | Verified |
| UR-05 | Version query | HLD §3.2 | see FR-08 | P08 | Verified |
| UR-06 | Clear usage errors, distinct status | HLD §6 | see FR-03, FR-05, FR-09 … FR-11 | P09, P10 | Verified |
| UR-07 | Exit status 0 on success | HLD §6 | `DPHApplication.m::+runWithArguments:count:` | `testDefaultGreeting`, P01 … P08 | Verified |
| UR-08 | Identical bytes on 3 OSes | HLD §5 | see NFR-01 | P01 … P10 on 3 OSes (CI) | Verified |
| UR-09 | Spaces and non-ASCII names | HLD §5 | see FR-02, CONV-05 | `testNonASCIINameIsUTF8`, `testNamedRepeatedGreeting` | Verified |
| UR-10 | Common CLI conventions | HLD §2 | see CONV rows | `DPHCommandLineTests.m` (all) | Verified |
| UR-11 | Instant start and finish | HLD §7 | see NFR-02 | MTP §4.4 | Verified |
| UR-12 | Standard install/uninstall | HLD §2 | see NFR-06 | `make roundtrip` (CI) | Verified |
| FR-01 | Default greeting | HLD §3.3, LLD §3.3, §3.4, §7 | `DPHValidation.m::+requestFromArguments:error:`, `DPHGreeting.m::+lineForName:` | `testDefaults`, `testDefaultName`, `testDefaultGreeting`, P01 | Verified |
| FR-02 | Named greeting, all spellings, verbatim | LLD §3.1, §3.4 | `DPHCommandLine.m::-scanLongOption:`, `DPHCommandLine.m::-scanShortOption:`, `DPHGreeting.m::+lineForName:` | `testValueSpellings`, `testValuesMayStartWithDash`, `testNameIsVerbatim`, P02, P03, P04, P06 | Verified |
| FR-03 | Empty name rejected | LLD §3.3 | `DPHValidation.m::+requestFromArguments:error:` | `testEmptyNameRejected`, `testEmptyAttachedValuesAreRecorded` | Verified |
| FR-04 | Repetition 1 … 1000, leading zeros | LLD §3.2, §3.6 | `DPHValidation.m::+parseCount:value:`, `DPHApplication.m::+runWithArguments:count:` | `testCountBoundaries`, `testCountLeadingZeros`, `testMaximumCount`, P05, P06 | Verified |
| FR-05 | Invalid count rejected | LLD §3.2, §3.3 | `DPHValidation.m::+parseCount:value:`, `DPHValidation.m::+requestFromArguments:error:` | `testCountRejectsNonDigits`, `testCountDoesNotOverflow`, `testInvalidCountRejected` | Verified |
| FR-06 | Last occurrence wins; validate the winner only | HLD D1, LLD §3.1, §3.3 | `DPHCommandLine.m::-storeValue:option:spelling:`, `DPHValidation.m::+requestFromArguments:error:` | `testLastOccurrenceWins`, `testOnlyTheWinningValueIsValidated` | Verified |
| FR-07 | Help text, scan order | LLD §3.1, §3.6 | `DPHCommandLine.m::-scanLongOption:`, `DPHApplication.m::DPHHelpText` | `testHelpAndVersionStopTheScan`, `testHelpAndVersion`, P07 | Verified |
| FR-08 | Version line | LLD §3.6 | `DPHApplication.m::DPHVersionText` | `testHelpAndVersion`, P08 | Verified |
| FR-09 | Operands rejected (after the scan) | LLD §3.1, §4 | `DPHCommandLine.m::-scan` | `testOperandsAreRejectedAfterTheScan`, `testOperandAndValueErrorsDoNotBeatHelp`, P10 | Verified |
| FR-10 | Unknown/malformed options, no abbreviations | LLD §3.1 | `DPHCommandLine.m::-scanLongOption:`, `DPHCommandLine.m::-scanShortOption:` | `testUnknownOptions`, `testMissingValues`, `testFlagsRejectValues`, P09 | Verified |
| FR-11 | Nothing on stdout on error | HLD D3, §6, LLD §2.3 | `DPHApplication.m::+runWithArguments:count:` | `testUsageErrorsWriteNoOutput`, `testDeliverWritesBothStreams`, P09, P10 | Verified |
| NFR-01 | Byte-identical, LF only | HLD §5, LLD §5 | `DPHPlatform.m::DPHPlatformUseBinaryStreams`, `DPHPlatform.m::DPHPlatformUTF8Arguments` | P01 … P10 on Linux, macOS, Windows (CI) | Verified |
| NFR-02 | < 100 ms, < 32 MiB (native build: limit applies as is, CONV-31) | HLD §7, LLD §6 | `DPHApplication.m::+runWithArguments:count:` | MTP §4.4 measurement | Verified |
| NFR-03 | No crash for any arguments | HLD §7, LLD §3.1, §3.2 | `DPHCommandLine.m::-scan`, `DPHValidation.m::+parseCount:value:` | `testCountDoesNotOverflow`, `testMissingValues`, MTP §4.3 | Verified |
| NFR-04 | Separate units | HLD §3.2 | `DPHCommandLine.m`, `DPHValidation.m`, `DPHGreeting.m`, `DPHOutput.m` | Design review (LLD §8) | Verified |
| NFR-05 | Pure, unit-tested greeting | LLD §3.4 | `DPHGreeting.m::+lineForName:` | `testIsPure`, `testDefaultName`, `testNameIsVerbatim` | Verified |
| NFR-06 | Every BASE-MAKEFILE target works | HLD §2 | `Makefile` (DP_* hooks) | `make check`, `make roundtrip` (CI, 3 OSes + container) | Verified |
| NFR-07 | No files, environment, subprocesses | HLD §1.1, D6 | whole program (no `fopen`, `getenv`, `NSProcessInfo`, `NSUserDefaults`, `NSTask`) | Inspection | Verified |
| CONV-01 | Canonical name, never argv[0] | LLD §2.4 | `DPHProgram.h::DPH_PROGRAM_NAME`, `DPHUsageError.m::-diagnostic` | `testEveryMessage`, P09, P10 | Verified |
| CONV-02 | Version format | LLD §3.6 | `DPHApplication.m::DPHVersionText` | `testHelpAndVersion`, P08 | Verified |
| CONV-03 | LF only, binary mode on Windows | HLD §5 | `DPHPlatform.m::DPHPlatformUseBinaryStreams`, `DPHOutput.m::+writeData:toStream:` | `testHelpAndVersion`, P01 … P10 on Windows | Verified |
| CONV-05 | Arguments as UTF-8; UTF-16 → UTF-8 on Windows | HLD §5, LLD §3.8 | `main.m::wmain`, `DPHPlatform.m::DPHPlatformUTF8Arguments` | `testNonASCIINameIsUTF8`, `testUnknownOptions`, P02 … P06 on Windows | Verified |
| CONV-06 | Locale-independent, plain ASCII numbers | HLD §5 | no locale use; `DPHValidation.m::+parseCount:value:` | `testCountRejectsNonDigits` | Verified |
| CONV-07 | Short options, attached or separate values | LLD §3.1 | `DPHCommandLine.m::-scanShortOption:` | `testValueSpellings`, `testBundledValueConsumesRestOfToken`, P03, P06 | Verified |
| CONV-08 | Long options, `=` or separate, no abbreviation | LLD §3.1 | `DPHCommandLine.m::-scanLongOption:`, `DPHCommandLine.m::LongNameIs` | `testValueSpellings`, `testUnknownOptions`, P02, P04, P05 | Verified |
| CONV-09 | `--` terminator | LLD §3.1 | `DPHCommandLine.m::-scan` | `testTerminatorMakesEverythingAnOperand` | Verified |
| CONV-10 | Operands (incl. `-`) | LLD §3.1 | `DPHCommandLine.m::-scan` | `testOperandsAreRejectedAfterTheScan`, P10 | Verified |
| CONV-11 | Last occurrence wins | LLD §3.1 | `DPHCommandLine.m::-storeValue:option:spelling:` | `testLastOccurrenceWins` | Verified |
| CONV-12 | Scan order; errors before output | HLD D2, D3, LLD §4 | `DPHCommandLine.m::-scan`, `DPHApplication.m::+runWithArguments:count:` | `testHelpAndVersionStopTheScan`, `testSyntaxErrorBeforeHelpWins`, `testOperandAndValueErrorsDoNotBeatHelp` | Verified |
| CONV-13 | Exact usage messages | LLD §2.4, §3.5 | `DPHUsageError.m::-diagnostic` | `testEveryMessage`, `DPHCommandLineTests.m` (error tests), P09, P10 | Verified |
| CONV-14 | "Try" line, exit 2 | LLD §3.5, §3.6 | `DPHUsageError.m::-diagnostic`, `DPHApplication.m::UsageFailure` | `testEveryMessage`, `testUsageErrorsWriteNoOutput`, P09, P10 | Verified |
| CONV-15 | Values quoted verbatim, `''` when empty | LLD §3.5 | `DPHUsageError.m::-diagnostic` | `testValuesAreQuotedVerbatim`, `testEmptyNameRejected` | Verified |
| CONV-18 | Exit statuses (as overridden by SRS §3.7) | HLD §6 | `DPHProgram.h` exit statuses, `DPHOutput.m::+deliverOutcome:output:error:` | `testDeliverWritesBothStreams`, P01 … P10 (`.exit` files) | Verified |
| CONV-22 | `--help` and `--version` accepted, no argument | LLD §3.1 | `DPHCommandLine.m::-scanLongOption:` | `testFlagsRejectValues`, P07, P08 | Verified |
| CONV-23 | Help text verbatim | LLD §3.6 | `DPHApplication.m::DPHHelpText` | `testHelpAndVersion`, P07 | Verified |
| CONV-24 | No crash or stack trace | HLD §7, D8 | all units (bounded scans, no exceptions) | MTP §4.3 | Verified |
| CONV-25 | EPIPE: stop promptly, no diagnostic | LLD §3.7, §5 | `DPHOutput.m::+deliverOutcome:output:error:` | MTP T-12 (`dp-hello -c 1000 \| head -1`) | Verified |
| CONV-26 | stdin not read | HLD §3.1 | no stdin access anywhere | Inspection; P01 … P10 (stdin is the null device) | Verified |
| CONV-31 | Memory limits apply to native builds | HLD §7 | native executable (no runtime baseline) | MTP §4.4 measurement | Verified |
| CONV-27 … CONV-30 | Harness conditions | MTP §3 | native executable in `build/bin` | P01 … P10 | Verified |

## 3. Backward traceability (test → requirement)

| Test | Type | Requirement(s) verified |
| :-- | :-- | :-- |
| P01 | black-box, public | FR-01, UR-01, UR-07 |
| P02 | black-box, public | FR-02, CONV-08 |
| P03 | black-box, public | FR-02, CONV-07 |
| P04 | black-box, public | FR-02, CONV-08 |
| P05 | black-box, public | FR-04 |
| P06 | black-box, public | FR-04, CONV-07 |
| P07 | black-box, public | FR-07, CONV-23 |
| P08 | black-box, public | FR-08, CONV-02 |
| P09 | black-box, public | FR-10, FR-11, CONV-13, CONV-14 |
| P10 | black-box, public | FR-09, FR-11, CONV-10, CONV-13 |
| `testNoArgumentsGreets` | unit | FR-01 |
| `testValueSpellings` | unit | FR-02, CONV-07, CONV-08 |
| `testBundledValueConsumesRestOfToken` | unit | FR-04, CONV-07 |
| `testValuesMayStartWithDash` | unit | FR-02 |
| `testEmptyAttachedValuesAreRecorded` | unit | FR-03 |
| `testLastOccurrenceWins` | unit | FR-06, CONV-11 |
| `testHelpAndVersionStopTheScan` | unit | FR-07, FR-08, CONV-12 |
| `testOperandAndValueErrorsDoNotBeatHelp` | unit | FR-07, FR-09, CONV-12 |
| `testSyntaxErrorBeforeHelpWins` | unit | CONV-12 |
| `testOperandsAreRejectedAfterTheScan` | unit | FR-09, CONV-10 |
| `testTerminatorMakesEverythingAnOperand` | unit | FR-09, CONV-09 |
| `testUnknownOptions` | unit | FR-10, CONV-05, CONV-08, CONV-13 |
| `testMissingValues` | unit | FR-10, CONV-13 |
| `testFlagsRejectValues` | unit | FR-10, CONV-22 |
| `testCountBoundaries` | unit | FR-04, FR-05 |
| `testCountLeadingZeros` | unit | FR-04 |
| `testCountRejectsNonDigits` | unit | FR-05, CONV-06 |
| `testCountDoesNotOverflow` | unit | FR-05, NFR-03 |
| `testDefaults` | unit | FR-01 |
| `testValidValues` | unit | FR-02, FR-04 |
| `testEmptyNameRejected` | unit | FR-03, CONV-15 |
| `testInvalidCountRejected` | unit | FR-05 |
| `testOnlyTheWinningValueIsValidated` | unit | FR-06 |
| `testNameIsCheckedBeforeCount` | unit | FR-03, FR-05 |
| `testDefaultName` | unit | FR-01, NFR-05 |
| `testNameIsVerbatim` | unit | FR-02, NFR-05 |
| `testNonASCIINameIsUTF8` | unit | FR-02, CONV-05 |
| `testIsPure` | unit | NFR-05 |
| `testEveryMessage` | unit | CONV-01, CONV-13, CONV-14 |
| `testValuesAreQuotedVerbatim` | unit | CONV-05, CONV-15 |
| `testSubjectLengthLimitsTheQuote` | unit | CONV-13 |
| `testDefaultGreeting` | unit | FR-01, UR-07 |
| `testNamedRepeatedGreeting` | unit | FR-02, FR-04, CONV-05 |
| `testMaximumCount` | unit | FR-04, NFR-02 |
| `testHelpAndVersion` | unit | FR-07, FR-08, CONV-02, CONV-03, CONV-12, CONV-23 |
| `testUsageErrorsWriteNoOutput` | unit | FR-03, FR-05, FR-09, FR-10, FR-11, CONV-14 |
| `testOperandIsReportedBeforeValues` | unit | FR-09 |
| `testDeliverWritesBothStreams` | unit | FR-11, CONV-18 |

## 4. Coverage summary

| Category | Total | Designed | Implemented | Verified |
| :-- | :-- | :-- | :-- | :-- |
| User requirements (UR) | 12 | 12 | 12 | 12 |
| Functional (FR) | 11 | 11 | 11 | 11 |
| Non-functional (NFR) | 7 | 7 | 7 | 7 |
| Conventions (CONV) | 25 applicable of 31 | 25 | 25 | 25 |

## 5. Gaps and justifications
No applicable requirement is unverified. Not applicable to dp-hello, which reads no input and
uses no paths: CONV-04 (copying input), CONV-16 and CONV-17 (file errors, several operands),
CONV-19 … CONV-21 (paths and traversal). The "missing operand" row of CONV-13 cannot occur.
CONV-27 … CONV-30 describe the test harness and are counted as four requirements above.
