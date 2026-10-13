#import "DPHPlatform.h"

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

void DPHPlatformUseBinaryStreams(void) {
  (void)_setmode(_fileno(stdout), _O_BINARY);
  (void)_setmode(_fileno(stderr), _O_BINARY);
}

/* One UTF-16 string as autoreleased NUL-terminated UTF-8 bytes (empty if conversion fails). */
static NSData* UTF8FromUTF16(const wchar_t* wide) {
  int size = WideCharToMultiByte(CP_UTF8, 0, wide, -1, NULL, 0, NULL, NULL);
  NSMutableData* utf8 = [NSMutableData dataWithLength:size > 0 ? (NSUInteger)size : 1];
  if (size > 0) {
    WideCharToMultiByte(CP_UTF8, 0, wide, -1, (char*)[utf8 mutableBytes], size, NULL, NULL);
  }
  return utf8;
}

const char* const* DPHPlatformUTF8Arguments(int count, wchar_t* wideArguments[]) {
  NSUInteger total = count > 0 ? (NSUInteger)count : 0;
  NSMutableArray* storage = [NSMutableArray arrayWithCapacity:total];
  NSMutableData* pointers = [NSMutableData dataWithLength:(total + 1) * sizeof(const char*)];
  const char** arguments = (const char**)[pointers mutableBytes];
  for (NSUInteger index = 0; index < total; index++) {
    NSData* argument = UTF8FromUTF16(wideArguments[index]);
    [storage addObject:argument];
    arguments[index] = (const char*)[argument bytes];
  }
  /* Keep the argument bytes alive as long as the pointer array: both are autoreleased. */
  [storage addObject:pointers];
  return arguments;
}

#else

void DPHPlatformUseBinaryStreams(void) {}

#endif
