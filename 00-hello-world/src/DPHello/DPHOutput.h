/* Output: the only unit that writes to the standard streams (CONV-03, CONV-25). */
#ifndef DPH_OUTPUT_H
#define DPH_OUTPUT_H

#import <Foundation/Foundation.h>

#include <stdio.h>

#import "DPHApplication.h"

@interface DPHOutput : NSObject

/* Writes every byte of `data` to `stream` and flushes it; returns NO on any write failure. */
+ (BOOL)writeData:(NSData*)data toStream:(FILE*)stream;

/*
 * Writes the outcome's stdout bytes to `output` and its stderr bytes to `error`, and returns
 * the exit status: the outcome's status, or DPHExitFailure if stdout could not be written
 * (for example a closed pipe, CONV-25). Diagnostics are best effort.
 */
+ (int)deliverOutcome:(DPHOutcome*)outcome output:(FILE*)output error:(FILE*)error;

@end

#endif
