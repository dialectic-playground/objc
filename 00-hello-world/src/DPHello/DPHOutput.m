#import "DPHOutput.h"

#import "DPHProgram.h"

@implementation DPHOutput

+ (BOOL)writeData:(NSData*)data toStream:(FILE*)stream {
  size_t length = (size_t)[data length];
  BOOL written = length == 0 || fwrite([data bytes], 1, length, stream) == length;
  return fflush(stream) == 0 && written;
}

+ (int)deliverOutcome:(DPHOutcome*)outcome output:(FILE*)output error:(FILE*)error {
  if (![self writeData:[outcome standardOutput] toStream:output]) {
    return DPHExitFailure;
  }
  /* There is nowhere left to report a failure to write a diagnostic. */
  (void)[self writeData:[outcome standardError] toStream:error];
  return [outcome status];
}

@end
