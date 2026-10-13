#import "DPHTestSupport.h"

#include <stdio.h>
#include <string.h>

static int gTests = 0;
static int gFailedTests = 0;
static int gChecks = 0;
static int gFailedChecks = 0;

void DPHRunTest(const char* name, DPHTestFunction test) {
  int failuresBefore = gFailedChecks;
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  test();
  [pool drain];
  gTests++;
  if (gFailedChecks != failuresBefore) {
    gFailedTests++;
    printf("FAIL %s\n", name);
  } else {
    printf("ok   %s\n", name);
  }
}

int DPHTestSummary(void) {
  printf("%d tests, %d assertions, %d failed tests, %d failed assertions\n", gTests, gChecks,
         gFailedTests, gFailedChecks);
  return gFailedChecks == 0 ? 0 : 1;
}

BOOL DPHCheck(BOOL passed, const char* expression, const char* file, int line) {
  gChecks++;
  if (!passed) {
    gFailedChecks++;
    printf("  %s:%d: assertion failed: %s\n", file, line, expression);
  }
  return passed;
}

/* Prints bytes with C escapes, so control characters and LF are visible in failure messages. */
static void PrintEscaped(const char* label, const char* bytes, size_t length) {
  printf("    %s \"", label);
  for (size_t index = 0; index < length; index++) {
    unsigned char byte = (unsigned char)bytes[index];
    if (byte == '\n') {
      printf("\\n");
    } else if (byte < 0x20 || byte == 0x7F) {
      printf("\\x%02x", byte);
    } else {
      putchar(byte);
    }
  }
  printf("\"\n");
}

BOOL DPHCheckBytes(NSData* actual, const char* expected, const char* file, int line) {
  size_t length = strlen(expected);
  BOOL passed = actual != nil && (size_t)[actual length] == length &&
                memcmp([actual bytes], expected, length) == 0;
  if (!DPHCheck(passed, "bytes match", file, line)) {
    PrintEscaped("expected", expected, length);
    if (actual != nil) {
      PrintEscaped("actual  ", (const char*)[actual bytes], (size_t)[actual length]);
    }
  }
  return passed;
}

BOOL DPHCheckString(const char* actual, const char* expected, const char* file, int line) {
  BOOL passed = (actual == NULL && expected == NULL) ||
                (actual != NULL && expected != NULL && strcmp(actual, expected) == 0);
  if (!DPHCheck(passed, "strings match", file, line)) {
    printf("    expected \"%s\"\n    actual   \"%s\"\n", expected != NULL ? expected : "(null)",
           actual != NULL ? actual : "(null)");
  }
  return passed;
}
