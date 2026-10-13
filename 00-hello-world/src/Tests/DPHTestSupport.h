/* A minimal unit-test runner: plain assertions that record failures and keep going. */
#ifndef DPH_TEST_SUPPORT_H
#define DPH_TEST_SUPPORT_H

#import <Foundation/Foundation.h>

/* A test case: a function that makes assertions. */
typedef void (*DPHTestFunction)(void);

/* Runs one test case inside its own autorelease pool and reports its result. */
void DPHRunTest(const char* name, DPHTestFunction test);

/* Prints the summary; returns 0 if every assertion passed, otherwise 1. */
int DPHTestSummary(void);

/* Records an assertion; returns `passed` so tests can stop early. */
BOOL DPHCheck(BOOL passed, const char* expression, const char* file, int line);

/* Asserts that `actual` holds exactly the bytes of the NUL-terminated string `expected`. */
BOOL DPHCheckBytes(NSData* actual, const char* expected, const char* file, int line);

/* Asserts that two C strings are equal (both NULL counts as equal). */
BOOL DPHCheckString(const char* actual, const char* expected, const char* file, int line);

#define DPH_RUN(test) DPHRunTest(#test, test)
#define DPH_ASSERT(expression) DPHCheck((expression) ? YES : NO, #expression, __FILE__, __LINE__)
#define DPH_ASSERT_BYTES(actual, expected) DPHCheckBytes((actual), (expected), __FILE__, __LINE__)
#define DPH_ASSERT_STRING(actual, expected) DPHCheckString((actual), (expected), __FILE__, __LINE__)

/* Number of elements of a fixed-size array. */
#define DPH_COUNT(array) (sizeof(array) / sizeof((array)[0]))

/* The test suites, one per unit. */
void DPHCommandLineTests(void);
void DPHValidationTests(void);
void DPHGreetingTests(void);
void DPHUsageErrorTests(void);
void DPHApplicationTests(void);

#endif
