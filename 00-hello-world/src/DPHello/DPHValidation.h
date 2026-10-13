/* Validation of the winning option values (FR-03, FR-04, FR-05, FR-06). */
#ifndef DPH_VALIDATION_H
#define DPH_VALIDATION_H

#import <Foundation/Foundation.h>

#import "DPHCommandLine.h"
#import "DPHUsageError.h"

#define DPH_DEFAULT_NAME "World"
#define DPH_DEFAULT_COUNT 1
#define DPH_MINIMUM_COUNT 1
#define DPH_MAXIMUM_COUNT 1000

/* A validated request: a non-empty NAME and a COUNT in 1 ... 1000. */
@interface DPHGreetingRequest : NSObject {
  const char* _name;
  NSUInteger _count;
}

+ (id)requestWithName:(const char*)name count:(NSUInteger)count;
- (const char*)name;
- (NSUInteger)count;

@end

@interface DPHValidation : NSObject

/*
 * Parses COUNT text: one or more ASCII digits (leading zeros allowed) whose value is within
 * 1 ... 1000. Stores the value in `*count` and returns YES, or returns NO without touching it.
 */
+ (BOOL)parseCount:(const char*)text value:(NSUInteger*)count;

/*
 * Turns the scanned (last-wins) values into a request, applying the defaults. On an empty NAME
 * or an invalid COUNT, returns nil and stores the DPHInvalidValue error in `*error`. NAME is
 * checked before COUNT.
 */
+ (DPHGreetingRequest*)requestFromArguments:(DPHParsedArguments*)arguments
                                      error:(DPHUsageError**)error;

@end

#endif
