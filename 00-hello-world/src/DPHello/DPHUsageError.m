#import "DPHUsageError.h"

#include <string.h>

#import "DPHProgram.h"

/* Every diagnostic starts with the canonical name (CONV-01) and ends with this line (CONV-14). */
static const char kPrefix[] = DPH_PROGRAM_NAME ": ";
static const char kTryHelp[] = "Try '" DPH_PROGRAM_NAME " --help' for more information.\n";

static void AppendText(NSMutableData* data, const char* text) {
  [data appendBytes:text length:strlen(text)];
}

@implementation DPHUsageError

+ (id)errorWithKind:(DPHUsageErrorKind)kind
            subject:(const char*)subject
             length:(NSUInteger)length
             option:(const char*)option {
  DPHUsageError* error = [[[self alloc] init] autorelease];
  error->_kind = kind;
  error->_subject = [[NSData alloc] initWithBytes:subject length:length];
  error->_option = option;
  return error;
}

+ (id)errorWithKind:(DPHUsageErrorKind)kind
            subject:(const char*)subject
             option:(const char*)option {
  return [self errorWithKind:kind subject:subject length:strlen(subject) option:option];
}

- (void)dealloc {
  [_subject release];
  [super dealloc];
}

- (DPHUsageErrorKind)kind {
  return _kind;
}

- (NSData*)subject {
  return _subject;
}

- (const char*)option {
  return _option;
}

- (NSData*)diagnostic {
  /* Each message is the literal text before the quoted subject and the text after it. */
  const char* before = "";
  const char* after = "'";
  switch (_kind) {
    case DPHInvalidOption:
      before = "invalid option -- '";
      break;
    case DPHUnrecognizedOption:
      before = "unrecognized option '";
      break;
    case DPHShortMissingValue:
      before = "option requires an argument -- '";
      break;
    case DPHLongMissingValue:
      before = "option '";
      after = "' requires an argument";
      break;
    case DPHLongUnexpectedValue:
      before = "option '";
      after = "' doesn't allow an argument";
      break;
    case DPHInvalidValue:
      before = "invalid argument '";
      after = "' for '";
      break;
    case DPHExtraOperand:
      before = "extra operand '";
      break;
  }
  NSMutableData* text = [NSMutableData data];
  AppendText(text, kPrefix);
  AppendText(text, before);
  [text appendData:_subject];
  AppendText(text, after);
  if (_kind == DPHInvalidValue) {
    AppendText(text, _option != NULL ? _option : "");
    AppendText(text, "'");
  }
  AppendText(text, "\n");
  AppendText(text, kTryHelp);
  return text;
}

@end
