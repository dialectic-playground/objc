/* End-to-end unit tests of the pure program flow and the output unit (FR-01 ... FR-11). */
#import "DPHApplication.h"
#import "DPHOutput.h"
#import "DPHProgram.h"
#import "DPHTestSupport.h"

#include <stdio.h>
#include <string.h>

#define TRY_HELP "Try 'dp-hello --help' for more information.\n"

/* Runs dp-hello on a NULL-terminated argument list. */
static DPHOutcome* Run(const char* const* arguments) {
  NSUInteger count = 0;
  while (arguments[count] != NULL) {
    count++;
  }
  return [DPHApplication runWithArguments:arguments count:count];
}

static void AssertOutcome(const char* const* arguments, const char* output, const char* error,
                          int status) {
  DPHOutcome* outcome = Run(arguments);
  DPH_ASSERT_BYTES([outcome standardOutput], output);
  DPH_ASSERT_BYTES([outcome standardError], error);
  DPH_ASSERT([outcome status] == status);
}

static void testDefaultGreeting(void) {
  const char* arguments[] = {NULL};
  AssertOutcome(arguments, "Hello, World!\n", "", DPHExitSuccess);
}

static void testNamedRepeatedGreeting(void) {
  const char* arguments[] = {"-c2", "-n", "Zo\xc3\xab", NULL};
  AssertOutcome(arguments, "Hello, Zo\xc3\xab!\nHello, Zo\xc3\xab!\n", "", DPHExitSuccess);
}

static void testMaximumCount(void) {
  const char* arguments[] = {"--count=1000", "--name=A", NULL};
  DPHOutcome* outcome = Run(arguments);
  DPH_ASSERT([[outcome standardOutput] length] == 1000 * strlen("Hello, A!\n"));
  DPH_ASSERT([outcome status] == DPHExitSuccess);
}

static void testHelpAndVersion(void) {
  const char* help[] = {"extra", "--count", "0", "--help", NULL};
  AssertOutcome(help,
                "Usage: dp-hello [OPTION]...\n"
                "Print a greeting to standard output.\n"
                "\n"
                "Options:\n"
                "  -n, --name=NAME     greet NAME instead of World\n"
                "  -c, --count=COUNT   print the greeting COUNT times (1-1000, default 1)\n"
                "      --help          display this help and exit\n"
                "      --version       output version information and exit\n",
                "", DPHExitSuccess);
  const char* version[] = {"--version", NULL};
  AssertOutcome(version, "dp-hello (dialectic-playground) 1.0.0\n", "", DPHExitSuccess);
}

static void testUsageErrorsWriteNoOutput(void) {
  const char* option[] = {"-x", "--help", NULL};
  AssertOutcome(option, "", "dp-hello: invalid option -- 'x'\n" TRY_HELP, DPHExitUsage);
  const char* operand[] = {"--", "-n", NULL};
  AssertOutcome(operand, "", "dp-hello: extra operand '-n'\n" TRY_HELP, DPHExitUsage);
  const char* count[] = {"-n", "Ada", "--count", "0", NULL};
  AssertOutcome(count, "", "dp-hello: invalid argument '0' for '--count'\n" TRY_HELP, DPHExitUsage);
  const char* name[] = {"--name", "", NULL};
  AssertOutcome(name, "", "dp-hello: invalid argument '' for '--name'\n" TRY_HELP, DPHExitUsage);
}

static void testOperandIsReportedBeforeValues(void) {
  const char* arguments[] = {"-c", "0", "extra", NULL};
  AssertOutcome(arguments, "", "dp-hello: extra operand 'extra'\n" TRY_HELP, DPHExitUsage);
}

/* Reads back everything written to `stream`. */
static NSData* Contents(FILE* stream) {
  NSMutableData* contents = [NSMutableData data];
  char buffer[256];
  size_t length;
  rewind(stream);
  while ((length = fread(buffer, 1, sizeof buffer, stream)) > 0) {
    [contents appendBytes:buffer length:length];
  }
  return contents;
}

static void testDeliverWritesBothStreams(void) {
  FILE* output = tmpfile();
  FILE* error = tmpfile();
  if (output != NULL && error != NULL) {
    const char* arguments[] = {"extra", NULL};
    DPH_ASSERT([DPHOutput deliverOutcome:Run(arguments) output:output error:error] == DPHExitUsage);
    DPH_ASSERT_BYTES(Contents(output), "");
    DPH_ASSERT_BYTES(Contents(error), "dp-hello: extra operand 'extra'\n" TRY_HELP);
  } else {
    printf("  (skipped: tmpfile() is unavailable)\n");
  }
  if (output != NULL) {
    fclose(output);
  }
  if (error != NULL) {
    fclose(error);
  }
}

void DPHApplicationTests(void) {
  DPH_RUN(testDefaultGreeting);
  DPH_RUN(testNamedRepeatedGreeting);
  DPH_RUN(testMaximumCount);
  DPH_RUN(testHelpAndVersion);
  DPH_RUN(testUsageErrorsWriteNoOutput);
  DPH_RUN(testOperandIsReportedBeforeValues);
  DPH_RUN(testDeliverWritesBothStreams);
}
