/* Usage errors (CONV-13, CONV-14) and their exact diagnostic text. */
#ifndef DPH_USAGE_ERROR_H
#define DPH_USAGE_ERROR_H

#import <Foundation/Foundation.h>

/* Every usage error dp-hello can report; each maps to one CONV-13 message. */
typedef enum {
  DPHInvalidOption,       /* unknown short option: subject is the option character */
  DPHUnrecognizedOption,  /* unknown long option: subject is the whole token */
  DPHShortMissingValue,   /* -n / -c without a value: subject is the letter */
  DPHLongMissingValue,    /* --name / --count without a value: subject is "--name" */
  DPHLongUnexpectedValue, /* --help=... / --version=...: subject is "--help" */
  DPHInvalidValue,        /* empty NAME or bad COUNT: subject is the value */
  DPHExtraOperand         /* any operand: subject is the first operand */
} DPHUsageErrorKind;

/*
 * One usage error. The subject is kept as raw UTF-8 bytes so that it is echoed exactly
 * (CONV-05, CONV-15). `option` is used only by DPHInvalidValue: the option as the user wrote
 * it ("-n" or "--name"); it must be a string with static storage duration.
 */
@interface DPHUsageError : NSObject {
  DPHUsageErrorKind _kind;
  NSData* _subject;
  const char* _option;
}

/* An autoreleased error whose subject is the first `length` bytes of `subject`. */
+ (id)errorWithKind:(DPHUsageErrorKind)kind
            subject:(const char*)subject
             length:(NSUInteger)length
             option:(const char*)option;

/* The same, with the whole NUL-terminated string `subject` as the subject. */
+ (id)errorWithKind:(DPHUsageErrorKind)kind subject:(const char*)subject option:(const char*)option;

- (DPHUsageErrorKind)kind;
- (NSData*)subject;
- (const char*)option;

/* The complete two-line diagnostic: the CONV-13 message and the CONV-14 line, each with LF. */
- (NSData*)diagnostic;

@end

#endif
