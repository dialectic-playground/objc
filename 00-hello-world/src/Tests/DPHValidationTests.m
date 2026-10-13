/* Unit tests for validation (FR-03, FR-04, FR-05, FR-06). */
#import "DPHCommandLine.h"
#import "DPHTestSupport.h"
#import "DPHValidation.h"

/* Validates a NULL-terminated argument list that scans without a syntax error. */
static DPHGreetingRequest* Validate(const char* const* arguments, DPHUsageError** error) {
  NSUInteger count = 0;
  while (arguments[count] != NULL) {
    count++;
  }
  DPHParsedArguments* parsed = [DPHCommandLine parseArguments:arguments count:count];
  DPH_ASSERT([parsed action] == DPHActionGreet);
  return [DPHValidation requestFromArguments:parsed error:error];
}

/* Asserts that `arguments` fail validation with `value` for `option`. */
static void AssertInvalid(const char* const* arguments, const char* value, const char* option) {
  DPHUsageError* error = nil;
  DPH_ASSERT(Validate(arguments, &error) == nil);
  if (DPH_ASSERT(error != nil)) {
    DPH_ASSERT([error kind] == DPHInvalidValue);
    DPH_ASSERT_BYTES([error subject], value);
    DPH_ASSERT_STRING([error option], option);
  }
}

static BOOL CountParses(const char* text, NSUInteger expected) {
  NSUInteger value = 0;
  return [DPHValidation parseCount:text value:&value] && value == expected;
}

static BOOL CountRejected(const char* text) {
  NSUInteger value = 77;
  return ![DPHValidation parseCount:text value:&value] && value == 77;
}

static void testCountBoundaries(void) {
  DPH_ASSERT(CountRejected("0"));
  DPH_ASSERT(CountParses("1", 1));
  DPH_ASSERT(CountParses("1000", 1000));
  DPH_ASSERT(CountRejected("1001"));
}

static void testCountLeadingZeros(void) {
  DPH_ASSERT(CountParses("007", 7));
  DPH_ASSERT(CountParses("0001000", 1000));
  DPH_ASSERT(CountRejected("000"));
}

static void testCountRejectsNonDigits(void) {
  const char* invalid[] = {"", "abc", "-1", "+1", " 1", "1 ", "1.0", "1e3", "0x10", "\xd9\xa3"};
  for (NSUInteger index = 0; index < DPH_COUNT(invalid); index++) {
    DPH_ASSERT(CountRejected(invalid[index]));
  }
}

static void testCountDoesNotOverflow(void) {
  DPH_ASSERT(CountRejected("99999999999999999999999999999999"));
  DPH_ASSERT(CountRejected("18446744073709551617"));
}

static void testDefaults(void) {
  const char* arguments[] = {NULL};
  DPHUsageError* error = nil;
  DPHGreetingRequest* request = Validate(arguments, &error);
  if (DPH_ASSERT(request != nil)) {
    DPH_ASSERT_STRING([request name], "World");
    DPH_ASSERT([request count] == 1);
  }
  DPH_ASSERT(error == nil);
}

static void testValidValues(void) {
  const char* arguments[] = {"--name", "Ada Lovelace", "-c", "007", NULL};
  DPHUsageError* error = nil;
  DPHGreetingRequest* request = Validate(arguments, &error);
  if (DPH_ASSERT(request != nil)) {
    DPH_ASSERT_STRING([request name], "Ada Lovelace");
    DPH_ASSERT([request count] == 7);
  }
}

static void testEmptyNameRejected(void) {
  const char* longForm[] = {"--name", "", NULL};
  AssertInvalid(longForm, "", "--name");
  const char* equalsForm[] = {"--name=", NULL};
  AssertInvalid(equalsForm, "", "--name");
  const char* shortForm[] = {"-n", "", NULL};
  AssertInvalid(shortForm, "", "-n");
}

static void testInvalidCountRejected(void) {
  const char* zero[] = {"--count", "0", NULL};
  AssertInvalid(zero, "0", "--count");
  const char* letters[] = {"-c", "abc", NULL};
  AssertInvalid(letters, "abc", "-c");
  const char* tooMany[] = {"-c1001", NULL};
  AssertInvalid(tooMany, "1001", "-c");
  const char* empty[] = {"--count=", NULL};
  AssertInvalid(empty, "", "--count");
}

static void testOnlyTheWinningValueIsValidated(void) {
  const char* arguments[] = {"-n", "", "-c", "0", "-n", "B", "--count=2", NULL};
  DPHUsageError* error = nil;
  DPHGreetingRequest* request = Validate(arguments, &error);
  if (DPH_ASSERT(request != nil)) {
    DPH_ASSERT_STRING([request name], "B");
    DPH_ASSERT([request count] == 2);
  }
  const char* lastInvalid[] = {"-c", "2", "--count", "x", NULL};
  AssertInvalid(lastInvalid, "x", "--count");
}

static void testNameIsCheckedBeforeCount(void) {
  const char* arguments[] = {"-c", "0", "-n", "", NULL};
  AssertInvalid(arguments, "", "-n");
}

void DPHValidationTests(void) {
  DPH_RUN(testCountBoundaries);
  DPH_RUN(testCountLeadingZeros);
  DPH_RUN(testCountRejectsNonDigits);
  DPH_RUN(testCountDoesNotOverflow);
  DPH_RUN(testDefaults);
  DPH_RUN(testValidValues);
  DPH_RUN(testEmptyNameRejected);
  DPH_RUN(testInvalidCountRejected);
  DPH_RUN(testOnlyTheWinningValueIsValidated);
  DPH_RUN(testNameIsCheckedBeforeCount);
}
