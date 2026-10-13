#import "DPHGreeting.h"

#include <string.h>

static const char kGreetingStart[] = "Hello, ";
static const char kGreetingEnd[] = "!\n";

@implementation DPHGreeting

+ (NSData*)lineForName:(const char*)name {
  NSMutableData* line = [NSMutableData data];
  [line appendBytes:kGreetingStart length:strlen(kGreetingStart)];
  [line appendBytes:name length:strlen(name)];
  [line appendBytes:kGreetingEnd length:strlen(kGreetingEnd)];
  return line;
}

@end
