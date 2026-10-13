/* Unit tests for greeting construction (FR-01, FR-02, NFR-05). */
#import "DPHGreeting.h"
#import "DPHTestSupport.h"

static void testDefaultName(void) {
  DPH_ASSERT_BYTES([DPHGreeting lineForName:"World"], "Hello, World!\n");
}

static void testNameIsVerbatim(void) {
  DPH_ASSERT_BYTES([DPHGreeting lineForName:"Ada Lovelace"], "Hello, Ada Lovelace!\n");
  DPH_ASSERT_BYTES([DPHGreeting lineForName:"-x"], "Hello, -x!\n");
  DPH_ASSERT_BYTES([DPHGreeting lineForName:"Hi! $USER 'q'"], "Hello, Hi! $USER 'q'!\n");
}

static void testNonASCIINameIsUTF8(void) {
  DPH_ASSERT_BYTES([DPHGreeting lineForName:"Zo\xc3\xab"], "Hello, Zo\xc3\xab!\n");
}

static void testIsPure(void) {
  NSData* first = [DPHGreeting lineForName:"Grace"];
  NSData* second = [DPHGreeting lineForName:"Grace"];
  DPH_ASSERT([first isEqualToData:second]);
}

void DPHGreetingTests(void) {
  DPH_RUN(testDefaultName);
  DPH_RUN(testNameIsVerbatim);
  DPH_RUN(testNonASCIINameIsUTF8);
  DPH_RUN(testIsPure);
}
