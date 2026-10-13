/* The program flow: scan, validate, then produce exactly one kind of output (FR-11). */
#ifndef DPH_APPLICATION_H
#define DPH_APPLICATION_H

#import <Foundation/Foundation.h>

/* The help text from the user manual, byte for byte (CONV-23). */
extern const char DPHHelpText[];

/* The version line (CONV-02). */
extern const char DPHVersionText[];

/* Everything one run produces: the bytes for stdout and stderr, and the exit status. */
@interface DPHOutcome : NSObject {
  NSData* _standardOutput;
  NSData* _standardError;
  int _status;
}

+ (id)outcomeWithOutput:(NSData*)output error:(NSData*)error status:(int)status;
- (NSData*)standardOutput;
- (NSData*)standardError;
- (int)status;

@end

@interface DPHApplication : NSObject

/*
 * Runs dp-hello on UTF-8 `arguments` (without the program name). Pure: it performs no I/O,
 * so a usage error can never leave partial output behind.
 */
+ (DPHOutcome*)runWithArguments:(const char* const*)arguments count:(NSUInteger)count;

@end

#endif
