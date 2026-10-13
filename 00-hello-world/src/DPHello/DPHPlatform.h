/* Platform layer: the only unit with operating-system-specific code (CONV-03, CONV-05). */
#ifndef DPH_PLATFORM_H
#define DPH_PLATFORM_H

#import <Foundation/Foundation.h>

/*
 * Switches stdout and stderr to binary mode on Windows, so LF is never translated to CRLF.
 * Does nothing on POSIX systems, where the streams are already byte-transparent.
 */
void DPHPlatformUseBinaryStreams(void);

#ifdef _WIN32
#include <wchar.h>

/*
 * Converts the UTF-16 arguments that wmain receives to `count` NUL-terminated UTF-8 strings.
 * The strings live in autoreleased storage, valid until the current autorelease pool drains.
 * Unpaired surrogates become U+FFFD.
 */
const char* const* DPHPlatformUTF8Arguments(int count, wchar_t* wideArguments[]);
#endif

#endif
