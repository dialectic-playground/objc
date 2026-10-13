/* Command-line scanning (CONV-07 ... CONV-12): arguments to raw option values or a usage error. */
#ifndef DPH_COMMAND_LINE_H
#define DPH_COMMAND_LINE_H

#import <Foundation/Foundation.h>

#import "DPHUsageError.h"

/* What the scan decided the invocation should do. */
typedef enum { DPHActionGreet, DPHActionHelp, DPHActionVersion, DPHActionUsageError } DPHAction;

/*
 * The result of a scan. NAME and COUNT are the last occurrences (CONV-11), not yet validated;
 * each option accessor returns the option as written ("-n" or "--name"), for diagnostics. All
 * of them are NULL when the option was not given. The value pointers point into the scanned
 * argument array, so they are valid as long as that array is.
 */
@interface DPHParsedArguments : NSObject {
  DPHAction _action;
  const char* _nameValue;
  const char* _nameOption;
  const char* _countValue;
  const char* _countOption;
  DPHUsageError* _error;
}

- (DPHAction)action;
- (const char*)nameValue;
- (const char*)nameOption;
- (const char*)countValue;
- (const char*)countOption;

/* The usage error when action is DPHActionUsageError, otherwise nil. */
- (DPHUsageError*)error;

@end

/* The hand-written option scanner (no third-party parsing library). */
@interface DPHCommandLine : NSObject

/*
 * Scans `arguments` (the UTF-8 command line without the program name) from left to right.
 * Stops at the first --help or --version, or at the first option syntax error. Operands are
 * only collected during the scan and rejected after it (CONV-12), so `extra --help` prints the
 * help.
 */
+ (DPHParsedArguments*)parseArguments:(const char* const*)arguments count:(NSUInteger)count;

@end

#endif
