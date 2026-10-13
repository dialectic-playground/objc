/* Unit tests for the exact diagnostic text (CONV-13, CONV-14, CONV-15). */
#import "DPHTestSupport.h"
#import "DPHUsageError.h"

#define TRY_HELP "Try 'dp-hello --help' for more information.\n"

static NSData* Diagnostic(DPHUsageErrorKind kind, const char* subject, const char* option) {
  return [[DPHUsageError errorWithKind:kind subject:subject option:option] diagnostic];
}

static void testEveryMessage(void) {
  DPH_ASSERT_BYTES(Diagnostic(DPHInvalidOption, "x", NULL),
                   "dp-hello: invalid option -- 'x'\n" TRY_HELP);
  DPH_ASSERT_BYTES(Diagnostic(DPHUnrecognizedOption, "--nme=Ada", NULL),
                   "dp-hello: unrecognized option '--nme=Ada'\n" TRY_HELP);
  DPH_ASSERT_BYTES(Diagnostic(DPHShortMissingValue, "n", NULL),
                   "dp-hello: option requires an argument -- 'n'\n" TRY_HELP);
  DPH_ASSERT_BYTES(Diagnostic(DPHLongMissingValue, "--count", NULL),
                   "dp-hello: option '--count' requires an argument\n" TRY_HELP);
  DPH_ASSERT_BYTES(Diagnostic(DPHLongUnexpectedValue, "--version", NULL),
                   "dp-hello: option '--version' doesn't allow an argument\n" TRY_HELP);
  DPH_ASSERT_BYTES(Diagnostic(DPHInvalidValue, "1001", "-c"),
                   "dp-hello: invalid argument '1001' for '-c'\n" TRY_HELP);
  DPH_ASSERT_BYTES(Diagnostic(DPHExtraOperand, "extra", NULL),
                   "dp-hello: extra operand 'extra'\n" TRY_HELP);
}

static void testValuesAreQuotedVerbatim(void) {
  DPH_ASSERT_BYTES(Diagnostic(DPHInvalidValue, "", "--name"),
                   "dp-hello: invalid argument '' for '--name'\n" TRY_HELP);
  DPH_ASSERT_BYTES(Diagnostic(DPHExtraOperand, "it's Zo\xc3\xab", NULL),
                   "dp-hello: extra operand 'it's Zo\xc3\xab'\n" TRY_HELP);
}

static void testSubjectLengthLimitsTheQuote(void) {
  DPHUsageError* error = [DPHUsageError errorWithKind:DPHInvalidOption
                                              subject:"xyz"
                                               length:1
                                               option:NULL];
  DPH_ASSERT_BYTES([error diagnostic], "dp-hello: invalid option -- 'x'\n" TRY_HELP);
}

void DPHUsageErrorTests(void) {
  DPH_RUN(testEveryMessage);
  DPH_RUN(testValuesAreQuotedVerbatim);
  DPH_RUN(testSubjectLengthLimitsTheQuote);
}
