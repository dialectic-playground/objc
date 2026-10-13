/* Unit-test entry point: runs every suite and exits 0 only if every assertion passed. */
#import <Foundation/Foundation.h>

#import "DPHTestSupport.h"

int main(void) {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  DPHCommandLineTests();
  DPHValidationTests();
  DPHGreetingTests();
  DPHUsageErrorTests();
  DPHApplicationTests();
  int status = DPHTestSummary();
  [pool drain];
  return status;
}
