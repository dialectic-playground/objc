/* Unit tests for the option scanner (CONV-07 ... CONV-13, FR-06, FR-07, FR-09, FR-10). */
#import "DPHCommandLine.h"
#import "DPHTestSupport.h"

/* Scans a NULL-terminated argument list. */
static DPHParsedArguments* Parse(const char* const* arguments) {
  NSUInteger count = 0;
  while (arguments[count] != NULL) {
    count++;
  }
  return [DPHCommandLine parseArguments:arguments count:count];
}

/* Asserts that scanning `arguments` stops with `kind` and the diagnostic subject `subject`. */
static void AssertUsageError(const char* const* arguments, DPHUsageErrorKind kind,
                             const char* subject) {
  DPHParsedArguments* parsed = Parse(arguments);
  if (DPH_ASSERT([parsed action] == DPHActionUsageError)) {
    DPH_ASSERT([[parsed error] kind] == kind);
    DPH_ASSERT_BYTES([[parsed error] subject], subject);
  }
}

static void testNoArgumentsGreets(void) {
  const char* arguments[] = {NULL};
  DPHParsedArguments* parsed = Parse(arguments);
  DPH_ASSERT([parsed action] == DPHActionGreet);
  DPH_ASSERT([parsed nameValue] == NULL);
  DPH_ASSERT([parsed countValue] == NULL);
  DPH_ASSERT([parsed error] == nil);
}

static void testValueSpellings(void) {
  const char* separate[] = {"-n", "Ada", "-c", "3", NULL};
  const char* attached[] = {"-nAda", "-c3", NULL};
  const char* longEquals[] = {"--name=Ada", "--count=3", NULL};
  const char* longSeparate[] = {"--name", "Ada", "--count", "3", NULL};
  const char* const* forms[] = {separate, attached, longEquals, longSeparate};
  const char* nameOptions[] = {"-n", "-n", "--name", "--name"};
  const char* countOptions[] = {"-c", "-c", "--count", "--count"};
  for (NSUInteger index = 0; index < DPH_COUNT(forms); index++) {
    DPHParsedArguments* parsed = Parse(forms[index]);
    DPH_ASSERT([parsed action] == DPHActionGreet);
    DPH_ASSERT_STRING([parsed nameValue], "Ada");
    DPH_ASSERT_STRING([parsed nameOption], nameOptions[index]);
    DPH_ASSERT_STRING([parsed countValue], "3");
    DPH_ASSERT_STRING([parsed countOption], countOptions[index]);
  }
}

static void testBundledValueConsumesRestOfToken(void) {
  const char* arguments[] = {"-c2", "-nKen", NULL};
  DPHParsedArguments* parsed = Parse(arguments);
  DPH_ASSERT_STRING([parsed countValue], "2");
  DPH_ASSERT_STRING([parsed nameValue], "Ken");
  const char* bundle[] = {"-nc5", NULL};
  parsed = Parse(bundle);
  DPH_ASSERT_STRING([parsed nameValue], "c5");
  DPH_ASSERT([parsed countValue] == NULL);
}

static void testValuesMayStartWithDash(void) {
  const char* separate[] = {"--name", "-x", "-n", "--help", NULL};
  DPHParsedArguments* parsed = Parse(separate);
  DPH_ASSERT([parsed action] == DPHActionGreet);
  DPH_ASSERT_STRING([parsed nameValue], "--help");
  const char* attached[] = {"--name=-x", NULL};
  DPH_ASSERT_STRING([Parse(attached) nameValue], "-x");
  const char* shortAttached[] = {"-n-x", NULL};
  DPH_ASSERT_STRING([Parse(shortAttached) nameValue], "-x");
}

static void testEmptyAttachedValuesAreRecorded(void) {
  const char* longEmpty[] = {"--name=", NULL};
  DPHParsedArguments* parsed = Parse(longEmpty);
  DPH_ASSERT([parsed action] == DPHActionGreet);
  DPH_ASSERT_STRING([parsed nameValue], "");
  const char* separateEmpty[] = {"-n", "", NULL};
  DPH_ASSERT_STRING([Parse(separateEmpty) nameValue], "");
}

static void testLastOccurrenceWins(void) {
  const char* arguments[] = {"-n", "A", "--count=0", "--name", "B", "-c", "2", NULL};
  DPHParsedArguments* parsed = Parse(arguments);
  DPH_ASSERT_STRING([parsed nameValue], "B");
  DPH_ASSERT_STRING([parsed nameOption], "--name");
  DPH_ASSERT_STRING([parsed countValue], "2");
  DPH_ASSERT_STRING([parsed countOption], "-c");
}

static void testHelpAndVersionStopTheScan(void) {
  const char* help[] = {"--help", "extra", "-x", NULL};
  DPH_ASSERT([Parse(help) action] == DPHActionHelp);
  const char* version[] = {"-n", "Ada", "--version", "--bogus", NULL};
  DPH_ASSERT([Parse(version) action] == DPHActionVersion);
  const char* first[] = {"--version", "--help", NULL};
  DPH_ASSERT([Parse(first) action] == DPHActionVersion);
}

static void testOperandAndValueErrorsDoNotBeatHelp(void) {
  const char* operand[] = {"extra", "--help", NULL};
  DPH_ASSERT([Parse(operand) action] == DPHActionHelp);
  const char* value[] = {"--count", "0", "--help", NULL};
  DPH_ASSERT([Parse(value) action] == DPHActionHelp);
  const char* emptyName[] = {"--name=", "--version", NULL};
  DPH_ASSERT([Parse(emptyName) action] == DPHActionVersion);
}

static void testSyntaxErrorBeforeHelpWins(void) {
  const char* arguments[] = {"-x", "--help", NULL};
  AssertUsageError(arguments, DPHInvalidOption, "x");
}

static void testOperandsAreRejectedAfterTheScan(void) {
  const char* operand[] = {"extra", NULL};
  AssertUsageError(operand, DPHExtraOperand, "extra");
  const char* firstOfMany[] = {"one", "-n", "Ada", "two", NULL};
  AssertUsageError(firstOfMany, DPHExtraOperand, "one");
  const char* dash[] = {"-", NULL};
  AssertUsageError(dash, DPHExtraOperand, "-");
}

static void testTerminatorMakesEverythingAnOperand(void) {
  const char* arguments[] = {"--", "-n", NULL};
  AssertUsageError(arguments, DPHExtraOperand, "-n");
  const char* helpAfter[] = {"--", "--help", NULL};
  AssertUsageError(helpAfter, DPHExtraOperand, "--help");
  const char* alone[] = {"-n", "Ada", "--", NULL};
  DPH_ASSERT([Parse(alone) action] == DPHActionGreet);
}

static void testUnknownOptions(void) {
  const char* shortOption[] = {"-x", NULL};
  AssertUsageError(shortOption, DPHInvalidOption, "x");
  const char* inBundleTail[] = {"-xn", "Ada", NULL};
  AssertUsageError(inBundleTail, DPHInvalidOption, "x");
  const char* nonASCII[] = {"-\xc3\xab", NULL};
  AssertUsageError(nonASCII, DPHInvalidOption, "\xc3\xab");
  const char* abbreviated[] = {"--nam", "Ada", NULL};
  AssertUsageError(abbreviated, DPHUnrecognizedOption, "--nam");
  const char* withValue[] = {"--nme=Ada", NULL};
  AssertUsageError(withValue, DPHUnrecognizedOption, "--nme=Ada");
  const char* longer[] = {"--names", NULL};
  AssertUsageError(longer, DPHUnrecognizedOption, "--names");
  const char* bareEquals[] = {"--=x", NULL};
  AssertUsageError(bareEquals, DPHUnrecognizedOption, "--=x");
}

static void testMissingValues(void) {
  const char* shortName[] = {"-n", NULL};
  AssertUsageError(shortName, DPHShortMissingValue, "n");
  const char* shortCount[] = {"-c", NULL};
  AssertUsageError(shortCount, DPHShortMissingValue, "c");
  const char* longName[] = {"--name", NULL};
  AssertUsageError(longName, DPHLongMissingValue, "--name");
  const char* longCount[] = {"-n", "Ada", "--count", NULL};
  AssertUsageError(longCount, DPHLongMissingValue, "--count");
}

static void testFlagsRejectValues(void) {
  const char* help[] = {"--help=1", NULL};
  AssertUsageError(help, DPHLongUnexpectedValue, "--help");
  const char* version[] = {"--version=", NULL};
  AssertUsageError(version, DPHLongUnexpectedValue, "--version");
}

void DPHCommandLineTests(void) {
  DPH_RUN(testNoArgumentsGreets);
  DPH_RUN(testValueSpellings);
  DPH_RUN(testBundledValueConsumesRestOfToken);
  DPH_RUN(testValuesMayStartWithDash);
  DPH_RUN(testEmptyAttachedValuesAreRecorded);
  DPH_RUN(testLastOccurrenceWins);
  DPH_RUN(testHelpAndVersionStopTheScan);
  DPH_RUN(testOperandAndValueErrorsDoNotBeatHelp);
  DPH_RUN(testSyntaxErrorBeforeHelpWins);
  DPH_RUN(testOperandsAreRejectedAfterTheScan);
  DPH_RUN(testTerminatorMakesEverythingAnOperand);
  DPH_RUN(testUnknownOptions);
  DPH_RUN(testMissingValues);
  DPH_RUN(testFlagsRejectValues);
}
