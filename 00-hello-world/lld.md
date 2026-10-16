<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [Low-Level Design (LLD) — Standard Terminal Hello World](#low-level-design-lld--standard-terminal-hello-world)
  - [1. Source layout](#1-source-layout)
  - [2. Data types](#2-data-types)
    - [2.1 `DPHParsedArguments` (`DPHCommandLine.h`)](#21-dphparsedarguments-dphcommandlineh)
    - [2.2 `DPHGreetingRequest` (`DPHValidation.h`)](#22-dphgreetingrequest-dphvalidationh)
    - [2.3 `DPHOutcome` (`DPHApplication.h`)](#23-dphoutcome-dphapplicationh)
    - [2.4 Error type: `DPHUsageError` (`DPHUsageError.h`)](#24-error-type-dphusageerror-dphusageerrorh)
  - [3. Module and function specifications](#3-module-and-function-specifications)
    - [3.1 `+[DPHCommandLine parseArguments:count:]`](#31-dphcommandline-parseargumentscount)
    - [3.2 `+[DPHValidation parseCount:value:]`](#32-dphvalidation-parsecountvalue)
    - [3.3 `+[DPHValidation requestFromArguments:error:]`](#33-dphvalidation-requestfromargumentserror)
    - [3.4 `+[DPHGreeting lineForName:]`](#34-dphgreeting-lineforname)
    - [3.5 `-[DPHUsageError diagnostic]`](#35--dphusageerror-diagnostic)
    - [3.6 `+[DPHApplication runWithArguments:count:]`](#36-dphapplication-runwithargumentscount)
    - [3.7 `+[DPHOutput writeData:toStream:]`, `+[DPHOutput deliverOutcome:output:error:]`](#37-dphoutput-writedatatostream-dphoutput-deliveroutcomeoutputerror)
    - [3.8 `DPHPlatformUseBinaryStreams`, `DPHPlatformUTF8Arguments`](#38-dphplatformusebinarystreams-dphplatformutf8arguments)
  - [4. Algorithms](#4-algorithms)
  - [5. Platform-specific details](#5-platform-specific-details)
  - [6. Resource management](#6-resource-management)
  - [7. Sequence of one invocation](#7-sequence-of-one-invocation)
  - [8. Design-to-code checklist](#8-design-to-code-checklist)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Low-Level Design (LLD) — Standard Terminal Hello World

| Field                   | Value                                                                                                       |
| :---------------------- | :---------------------------------------------------------------------------------------------------------- |
| Project                 | `00-hello-world`                                                                                            |
| Tools                   | dp-hello                                                                                                    |
| Implementation language | Objective-C with Foundation (GCC + GNUstep Base, Apple Clang + Foundation, Clang + libobjc2 + GNUstep Base) |
| Author                  | Brandon Perkins                                                                                             |
| Version / date          | 1.0 — 2026-10-13                                                                                            |
| Status                  | Approved                                                                                                    |
| Inputs                  | `hld.md`, `specs/SRS.md`, `shared/CLI-CONVENTIONS.md`                                                       |

## 1. Source layout

```text
src/
├── DPHello/
│   ├── main.m                main (POSIX) / wmain (Windows): pool, arguments, run, deliver
│   ├── DPHPlatform.[hm]      DPHPlatformUseBinaryStreams, DPHPlatformUTF8Arguments (Windows)
│   ├── DPHApplication.[hm]   DPHOutcome, DPHApplication, DPHHelpText, DPHVersionText
│   ├── DPHCommandLine.[hm]   DPHParsedArguments, DPHCommandLine (and the private DPHScanner)
│   ├── DPHValidation.[hm]    DPHGreetingRequest, DPHValidation, defaults and limits
│   ├── DPHGreeting.[hm]      DPHGreeting
│   ├── DPHUsageError.[hm]    DPHUsageErrorKind, DPHUsageError
│   ├── DPHOutput.[hm]        DPHOutput
│   └── DPHProgram.h          DPH_PROGRAM_NAME, DPH_PROGRAM_VERSION, exit statuses
└── Tests/
    ├── DPHTestSupport.[hm]   runner (DPHRunTest, DPHTestSummary) and assertion macros
    ├── DPHTestMain.m         test executable entry point
    └── DPHCommandLineTests.m, DPHValidationTests.m, DPHGreetingTests.m,
        DPHUsageErrorTests.m, DPHApplicationTests.m
```

The unit-test executable links every `DPHello/*.m` except `main.m`. Every file is compiled
with `-std=gnu11` and manual reference counting; objects are created autoreleased, and
classes that hold objects retain them and release them in `-dealloc`.

## 2. Data types

### 2.1 `DPHParsedArguments` (`DPHCommandLine.h`)

| Field                       | Type                                                                                       | Default          | Constraint / invariant                                   | SRS                   |
| :-------------------------- | :----------------------------------------------------------------------------------------- | :--------------- | :------------------------------------------------------- | :-------------------- |
| `action`                    | `DPHAction` (`DPHActionGreet`, `DPHActionHelp`, `DPHActionVersion`, `DPHActionUsageError`) | `DPHActionGreet` | Set when the scan stops                                  | FR-07, FR-08, CONV-12 |
| `nameValue`, `nameOption`   | `const char*`                                                                              | `NULL`           | Last occurrence; option is `"-n"` or `"--name"`          | FR-02, FR-06          |
| `countValue`, `countOption` | `const char*`                                                                              | `NULL`           | Last occurrence; option is `"-c"` or `"--count"`         | FR-04, FR-06          |
| `error`                     | `DPHUsageError*` (retained)                                                                | `nil`            | Non-nil exactly when the action is `DPHActionUsageError` | FR-09, FR-10          |

Values point into the scanned argument array; options point at string literals.

### 2.2 `DPHGreetingRequest` (`DPHValidation.h`)

| Field   | Type          | Default   | Constraint / invariant | SRS                 |
| :------ | :------------ | :-------- | :--------------------- | :------------------ |
| `name`  | `const char*` | `"World"` | Non-empty              | FR-01, FR-02, FR-03 |
| `count` | `NSUInteger`  | 1         | 1 ≤ count ≤ 1000       | FR-04, FR-05        |

### 2.3 `DPHOutcome` (`DPHApplication.h`)

| Field            | Type               | Constraint / invariant                     | SRS   |
| :--------------- | :----------------- | :----------------------------------------- | :---- |
| `standardOutput` | `NSData*` (copied) | Empty whenever `status` is 2               | FR-11 |
| `standardError`  | `NSData*` (copied) | Empty whenever `status` is 0               | §3.6  |
| `status`         | `int`              | `DPHExitSuccess` (0) or `DPHExitUsage` (2) | §3.7  |

### 2.4 Error type: `DPHUsageError` (`DPHUsageError.h`)

`{kind, subject, option}`: `subject` is an `NSData` copy of the quoted bytes (so an unknown
short option is quoted as a whole UTF-8 character), `option` the option as written (only for
`DPHInvalidValue`). Every variant exits with status 2 and is followed by
`Try 'dp-hello --help' for more information.`

| Variant                  | Diagnostic (stderr, first line)                       | Exit status |
| :----------------------- | :---------------------------------------------------- | :---------- |
| `DPHInvalidOption`       | `dp-hello: invalid option -- 'x'`                     | 2           |
| `DPHUnrecognizedOption`  | `dp-hello: unrecognized option '<token>'`             | 2           |
| `DPHShortMissingValue`   | `dp-hello: option requires an argument -- 'n'`        | 2           |
| `DPHLongMissingValue`    | `dp-hello: option '--name' requires an argument`      | 2           |
| `DPHLongUnexpectedValue` | `dp-hello: option '--help' doesn't allow an argument` | 2           |
| `DPHInvalidValue`        | `dp-hello: invalid argument '<value>' for '<option>'` | 2           |
| `DPHExtraOperand`        | `dp-hello: extra operand '<operand>'`                 | 2           |

## 3. Module and function specifications

### 3.1 `+[DPHCommandLine parseArguments:count:]`

- **Signature:** `+ (DPHParsedArguments*)parseArguments:(const char* const*)arguments count:(NSUInteger)count`
- **Responsibility:** scan the arguments (without the program name) left to right.
- **Preconditions:** `arguments[0 … count-1]` are NUL-terminated UTF-8 strings; an
  autorelease pool is in place.
- **Postconditions / return value:** an autoreleased result: the action plus the last
  `--name`/`--count` occurrences, or the usage error.
- **Errors:** every variant except `DPHInvalidValue`.
- **Algorithm:** a private `DPHScanner` walks the tokens. After `--` every token is an
  operand; `--` sets that state; a token starting with `--` goes to `-scanLongOption:`;
  `-` plus at least one byte goes to `-scanShortOption:`; anything else (including `-`) is an
  operand, and the first one is remembered. The scan stops at the first option syntax error,
  `--help`, or `--version`. After it, if the action is still greet and an operand was seen,
  the result is `DPHExtraOperand`. `-scanLongOption:` splits at the first `=`, compares the
  name exactly with `name`, `count`, `help`, `version` (no abbreviations, `LongNameIs`), takes
  the value from after `=` or the next token (which may start with `-`), and rejects a flag
  given `=…`. `-scanShortOption:` looks only at the first letter, because both short options
  take a value: the rest of the token, or else the next token, is the value.
- **Complexity:** time O(total argument bytes), memory O(1) besides the result.
- **Satisfies:** FR-02, FR-06 … FR-10, CONV-07 … CONV-13
- **Unit tests:** every test in `src/Tests/DPHCommandLineTests.m` (listed in `rtm.md` §3)

### 3.2 `+[DPHValidation parseCount:value:]`

- **Signature:** `+ (BOOL)parseCount:(const char*)text value:(NSUInteger*)count`
- **Responsibility:** accept one or more ASCII digits with a value in 1 … 1000.
- **Postconditions:** on success `*count` holds the value; on failure it is unchanged.
- **Algorithm:** reject an empty string or any byte outside `'0'…'9'`; accumulate the value
  but stop multiplying once it exceeds 1000 (saturation, so no overflow); check the range.
- **Complexity:** O(len(text)), O(1) memory.
- **Satisfies:** FR-04, FR-05, CONV-06
- **Unit tests:** `testCountBoundaries`, `testCountLeadingZeros`, `testCountRejectsNonDigits`,
  `testCountDoesNotOverflow`

### 3.3 `+[DPHValidation requestFromArguments:error:]`

- **Signature:** `+ (DPHGreetingRequest*)requestFromArguments:(DPHParsedArguments*)arguments error:(DPHUsageError**)error`
- **Responsibility:** check the winning values and apply the defaults.
- **Errors:** returns `nil` and stores `DPHInvalidValue` for an empty NAME (checked first) or an
  invalid COUNT, with the option as written.
- **Satisfies:** FR-01, FR-03, FR-05, FR-06, CONV-15
- **Unit tests:** `testDefaults`, `testValidValues`, `testEmptyNameRejected`,
  `testInvalidCountRejected`, `testOnlyTheWinningValueIsValidated`,
  `testNameIsCheckedBeforeCount`

### 3.4 `+[DPHGreeting lineForName:]`

- **Signature:** `+ (NSData*)lineForName:(const char*)name`
- **Responsibility:** the bytes `Hello,` + NAME + `!` + LF; pure (no I/O, no state).
- **Return value:** an autoreleased `NSData`; NAME's bytes are appended verbatim.
- **Satisfies:** FR-01, FR-02, NFR-05, CONV-05
- **Unit tests:** `testDefaultName`, `testNameIsVerbatim`, `testNonASCIINameIsUTF8`,
  `testIsPure`

### 3.5 `-[DPHUsageError diagnostic]`

- **Signature:** `- (NSData*)diagnostic`
- **Responsibility:** the complete two-line diagnostic (table §2.4): prefix `dp-hello:`, the
  kind's text before the quoted subject, the subject bytes, the text after it, LF, and the
  CONV-14 line; pure.
- **Satisfies:** CONV-01, CONV-13, CONV-14, CONV-15
- **Unit tests:** `testEveryMessage`, `testValuesAreQuotedVerbatim`,
  `testSubjectLengthLimitsTheQuote`

### 3.6 `+[DPHApplication runWithArguments:count:]`

- **Signature:** `+ (DPHOutcome*)runWithArguments:(const char* const*)arguments count:(NSUInteger)count`
- **Responsibility:** parse → (help text | version text | usage error | validate → greet);
  pure: performs no I/O.
- **Algorithm:** help and version return `DPHHelpText`/`DPHVersionText` with status 0; a
  usage error returns its diagnostic as stderr with status 2; a greeting builds the line once
  and appends it `count` times to an `NSMutableData` of capacity `length × count`.
- **Complexity:** O(len(NAME) × COUNT) time and memory (at most about 1000 lines).
- **Satisfies:** FR-01, FR-04, FR-07, FR-08, FR-11, SRS §3.7, CONV-02, CONV-23
- **Unit tests:** `testDefaultGreeting`, `testNamedRepeatedGreeting`, `testMaximumCount`,
  `testHelpAndVersion`, `testUsageErrorsWriteNoOutput`, `testOperandIsReportedBeforeValues`

### 3.7 `+[DPHOutput writeData:toStream:]`, `+[DPHOutput deliverOutcome:output:error:]`

- **Responsibility:** the only writes to the standard streams. `writeData:toStream:` calls
  `fwrite` once and `fflush`, and returns `NO` on any failure. `deliverOutcome:` writes stdout
  first; if that fails (for example a closed pipe on Windows) it returns 1 without writing
  stderr; otherwise it writes stderr (best effort) and returns the outcome's status.
- **Satisfies:** CONV-03, CONV-25
- **Unit tests:** `testDeliverWritesBothStreams`; P01 … P10

### 3.8 `DPHPlatformUseBinaryStreams`, `DPHPlatformUTF8Arguments`

- **Signatures:** `void DPHPlatformUseBinaryStreams(void)`;
  `const char* const* DPHPlatformUTF8Arguments(int count, wchar_t* wideArguments[])` (Windows)
- **Responsibility:** Windows: `_setmode(_fileno(stdout|stderr), _O_BINARY)`; convert each
  `wchar_t*` argument with `WideCharToMultiByte(CP_UTF8, 0, …)` into an autoreleased
  `NSMutableData` and return a NULL-terminated pointer array that is itself autoreleased
  storage (valid until `main` drains its pool). POSIX: no-op.
- **Satisfies:** NFR-01, CONV-03, CONV-05
- **Unit tests:** black-box P01 … P10 on Windows CI (UTF-8 names: hidden suite)

## 4. Algorithms

Only the scan is non-trivial; see §3.1. Scanning stops at the first decisive token, so
`--help extra -x` prints help (FR-07) while `-x --help` reports `-x` (CONV-12). Values are
not validated during the scan (FR-06), so `--count 0 --help` prints help. Operands are only
collected during the scan and rejected after it (CONV-12 as clarified in curriculum v1.4.0),
so `extra --help` prints help while `extra -x` reports `-x`, and `extra` alone reports the
operand. When both an operand and an invalid value are present, the operand is reported
(it is detected by the scanner, before validation). An unknown short option is quoted as its
whole UTF-8 sequence (lead byte plus continuation bytes), so `-ë` gives
`invalid option -- 'ë'` rather than a broken byte.

## 5. Platform-specific details

| Concern                  | Linux                                         | macOS                                                  | Windows                                                           | Abstraction                                      |
| :----------------------- | :-------------------------------------------- | :----------------------------------------------------- | :---------------------------------------------------------------- | :----------------------------------------------- |
| Argument encoding        | bytes (UTF-8)                                 | bytes (UTF-8)                                          | UTF-16 via `wmain` → UTF-8                                        | `main.m`, `DPHPlatformUTF8Arguments`             |
| Newline translation      | none                                          | none                                                   | text mode would write CRLF: `_O_BINARY`                           | `DPHPlatformUseBinaryStreams`                    |
| Entry point / link flags | `main`                                        | `main`                                                 | `wmain`, linked with `-municode`                                  | `main.m`, project `Makefile`                     |
| Compiler / Foundation    | GCC (gobjc) + GNUstep Base (`gnustep-config`) | Apple Clang `-x objective-c` + `-framework Foundation` | Clang + libobjc2 + GNUstep Base (`gnustep-config`, MSYS2 CLANG64) | `OBJC`, `OBJC_CFLAGS`, `OBJC_LIBS` in `Makefile` |
| Language subset          | no ARC, no `@autoreleasepool`, no literals    | same source                                            | same source                                                       | MRC + `NSAutoreleasePool`                        |
| Broken pipe              | SIGPIPE ends the process                      | same                                                   | `fwrite` fails, status 1                                          | `+[DPHOutput deliverOutcome:output:error:]`      |

## 6. Resource management

No files, sockets, or processes are opened. `main` owns one `NSAutoreleasePool`, drained
before returning; every object is created autoreleased into it, and the only retained
references (`DPHParsedArguments.error`, `DPHUsageError.subject`, `DPHOutcome`'s data) are
released in `-dealloc`. The largest buffer is the greeting output, at most 1000 × (len(NAME)

- 1. bytes; on Windows the UTF-8 arguments are O(total argument length). Peak RSS is about
     15 MiB, almost all of it the GNUstep Base library (MTP §4.4).

## 7. Sequence of one invocation

P01, `dp-hello`: `main` → `NSAutoreleasePool` → `DPHPlatformUseBinaryStreams` (no-op) →
`+[DPHApplication runWithArguments:argv + 1 count:0]` → `+[DPHCommandLine
parseArguments:count:]` returns greet with no values → `+[DPHValidation
requestFromArguments:error:]` yields `{"World", 1}` → `+[DPHGreeting lineForName:"World"]`
returns the 14 bytes `Hello, World!\n` → appended once → outcome `{14 bytes, empty, 0}` →
`+[DPHOutput deliverOutcome:output:error:]` writes and flushes stdout (stderr is empty) and
returns 0 → the pool is drained → exit status 0.

## 8. Design-to-code checklist

| HLD component         | LLD section      | Source file(s)                                    | Unit-test file(s)                            |
| :-------------------- | :--------------- | :------------------------------------------------ | :------------------------------------------- |
| `DPHCommandLine`      | §2.1, §3.1       | `src/DPHello/DPHCommandLine.m`                    | `src/Tests/DPHCommandLineTests.m`            |
| `DPHValidation`       | §2.2, §3.2, §3.3 | `src/DPHello/DPHValidation.m`                     | `src/Tests/DPHValidationTests.m`             |
| `DPHGreeting`         | §3.4             | `src/DPHello/DPHGreeting.m`                       | `src/Tests/DPHGreetingTests.m`               |
| `DPHUsageError`       | §2.4, §3.5       | `src/DPHello/DPHUsageError.m`                     | `src/Tests/DPHUsageErrorTests.m`             |
| `DPHApplication`      | §2.3, §3.6       | `src/DPHello/DPHApplication.m`                    | `src/Tests/DPHApplicationTests.m`            |
| `DPHOutput`           | §3.7             | `src/DPHello/DPHOutput.m`                         | `src/Tests/DPHApplicationTests.m`, P01 … P10 |
| `DPHPlatform`, `main` | §3.8, §5         | `src/DPHello/DPHPlatform.m`, `src/DPHello/main.m` | P01 … P10 (Windows CI)                       |
| `DPHProgram`          | §2.3             | `src/DPHello/DPHProgram.h`                        | `testEveryMessage`, `testHelpAndVersion`     |
