/* Greeting construction (NFR-05): a pure function of NAME. */
#ifndef DPH_GREETING_H
#define DPH_GREETING_H

#import <Foundation/Foundation.h>

@interface DPHGreeting : NSObject

/*
 * The greeting line "Hello, " NAME "!" LF as UTF-8 bytes. NAME is copied verbatim (CONV-05);
 * the result depends on nothing but `name`.
 */
+ (NSData*)lineForName:(const char*)name;

@end

#endif
