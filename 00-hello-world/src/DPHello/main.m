/*
 * dp-hello entry point. POSIX passes UTF-8 bytes to main; on Windows (linked with -municode)
 * wmain receives the UTF-16 command line, which is converted to UTF-8 first (CONV-05).
 */
#import <Foundation/Foundation.h>

#include <stdio.h>

#import "DPHApplication.h"
#import "DPHOutput.h"
#import "DPHPlatform.h"

/* Runs dp-hello on the UTF-8 argument vector (program name first) and writes its outcome. */
static int RunAndDeliver(int argc, const char* const* argv) {
  NSUInteger count = argc > 0 ? (NSUInteger)argc - 1 : 0;
  DPHOutcome* outcome = [DPHApplication runWithArguments:argv + 1 count:count];
  return [DPHOutput deliverOutcome:outcome output:stdout error:stderr];
}

#ifdef _WIN32
int wmain(int argc, wchar_t* argv[]) {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  DPHPlatformUseBinaryStreams();
  int status = RunAndDeliver(argc, DPHPlatformUTF8Arguments(argc, argv));
  [pool drain];
  return status;
}
#else
int main(int argc, char* argv[]) {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  DPHPlatformUseBinaryStreams();
  int status = RunAndDeliver(argc, (const char* const*)argv);
  [pool drain];
  return status;
}
#endif
