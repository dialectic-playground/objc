#import "DPHValidation.h"

@implementation DPHGreetingRequest

+ (id)requestWithName:(const char*)name count:(NSUInteger)count {
  DPHGreetingRequest* request = [[[self alloc] init] autorelease];
  request->_name = name;
  request->_count = count;
  return request;
}

- (const char*)name {
  return _name;
}

- (NSUInteger)count {
  return _count;
}

@end

@implementation DPHValidation

+ (BOOL)parseCount:(const char*)text value:(NSUInteger*)count {
  if (text[0] == '\0') {
    return NO;
  }
  NSUInteger value = 0;
  for (const char* digit = text; *digit != '\0'; digit++) {
    if (*digit < '0' || *digit > '9') {
      return NO;
    }
    /* Saturate above the maximum so long digit strings cannot overflow. */
    if (value <= DPH_MAXIMUM_COUNT) {
      value = value * 10 + (NSUInteger)(*digit - '0');
    }
  }
  if (value < DPH_MINIMUM_COUNT || value > DPH_MAXIMUM_COUNT) {
    return NO;
  }
  *count = value;
  return YES;
}

+ (DPHGreetingRequest*)requestFromArguments:(DPHParsedArguments*)arguments
                                      error:(DPHUsageError**)error {
  const char* name = DPH_DEFAULT_NAME;
  NSUInteger count = DPH_DEFAULT_COUNT;
  if ([arguments nameValue] != NULL) {
    name = [arguments nameValue];
    if (name[0] == '\0') {
      *error = [DPHUsageError errorWithKind:DPHInvalidValue
                                    subject:name
                                     option:[arguments nameOption]];
      return nil;
    }
  }
  if ([arguments countValue] != NULL && ![self parseCount:[arguments countValue] value:&count]) {
    *error = [DPHUsageError errorWithKind:DPHInvalidValue
                                  subject:[arguments countValue]
                                   option:[arguments countOption]];
    return nil;
  }
  return [DPHGreetingRequest requestWithName:name count:count];
}

@end
