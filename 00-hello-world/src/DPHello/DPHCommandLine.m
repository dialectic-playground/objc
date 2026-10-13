#import "DPHCommandLine.h"

#include <string.h>

/* A value option: its short letter and both spellings, as written in diagnostics. */
typedef struct {
  char letter;
  const char* shortSpelling;
  const char* longSpelling;
} DPHValueOption;

static const DPHValueOption kNameOption = {'n', "-n", "--name"};
static const DPHValueOption kCountOption = {'c', "-c", "--count"};

/* A long option without a value and the action it selects. */
typedef struct {
  const char* spelling;
  DPHAction action;
} DPHFlagOption;

static const DPHFlagOption kFlagOptions[] = {{"--help", DPHActionHelp},
                                             {"--version", DPHActionVersion}};

/* True when the long option name `name` (of `length` bytes) is exactly `spelling` minus "--". */
static BOOL LongNameIs(const char* name, size_t length, const char* spelling) {
  return strlen(spelling + 2) == length && strncmp(name, spelling + 2, length) == 0;
}

/* Length of the UTF-8 sequence starting at `text`, so `-ë` is quoted as one character. */
static NSUInteger UTF8CharacterLength(const char* text) {
  unsigned char lead = (unsigned char)text[0];
  NSUInteger expected = lead >= 0xF0 ? 4 : lead >= 0xE0 ? 3 : lead >= 0xC0 ? 2 : 1;
  NSUInteger length = 1;
  while (length < expected && ((unsigned char)text[length] & 0xC0) == 0x80) {
    length++;
  }
  return length;
}

@interface DPHParsedArguments ()
- (id)initWithAction:(DPHAction)action
           nameValue:(const char*)nameValue
          nameOption:(const char*)nameOption
          countValue:(const char*)countValue
         countOption:(const char*)countOption
               error:(DPHUsageError*)error;
@end

@implementation DPHParsedArguments

- (id)initWithAction:(DPHAction)action
           nameValue:(const char*)nameValue
          nameOption:(const char*)nameOption
          countValue:(const char*)countValue
         countOption:(const char*)countOption
               error:(DPHUsageError*)error {
  self = [super init];
  if (self != nil) {
    _action = action;
    _nameValue = nameValue;
    _nameOption = nameOption;
    _countValue = countValue;
    _countOption = countOption;
    _error = [error retain];
  }
  return self;
}

- (void)dealloc {
  [_error release];
  [super dealloc];
}

- (DPHAction)action {
  return _action;
}

- (const char*)nameValue {
  return _nameValue;
}

- (const char*)nameOption {
  return _nameOption;
}

- (const char*)countValue {
  return _countValue;
}

- (const char*)countOption {
  return _countOption;
}

- (DPHUsageError*)error {
  return _error;
}

@end

/* Scanner state for one call of +parseArguments:count:. */
@interface DPHScanner : NSObject {
  const char* const* _tokens;
  NSUInteger _count;
  NSUInteger _next;
  DPHAction _action;
  const char* _values[2];  /* indexed like kValueOptions: NAME, COUNT */
  const char* _options[2]; /* the spelling each value was given with */
  DPHUsageError* _error;   /* autoreleased; lives as long as the caller's pool */
}
@end

static const DPHValueOption* const kValueOptions[] = {&kNameOption, &kCountOption};

@implementation DPHScanner

- (id)initWithTokens:(const char* const*)tokens count:(NSUInteger)count {
  self = [super init];
  if (self != nil) {
    _tokens = tokens;
    _count = count;
    _action = DPHActionGreet;
  }
  return self;
}

/* Records a usage error and returns NO: the scan stops at the first one (CONV-12). */
- (BOOL)failWithKind:(DPHUsageErrorKind)kind
             subject:(const char*)subject
              length:(NSUInteger)length {
  _action = DPHActionUsageError;
  _error = [DPHUsageError errorWithKind:kind subject:subject length:length option:NULL];
  return NO;
}

/* Takes the next token as an option value, even if it starts with '-' (FR-02). */
- (const char*)takeNextToken {
  return _next < _count ? _tokens[_next++] : NULL;
}

/* Stores the latest occurrence of value option `index`; the last one wins (CONV-11). */
- (void)storeValue:(const char*)value option:(NSUInteger)index spelling:(const char*)spelling {
  _values[index] = value;
  _options[index] = spelling;
}

/* Handles a token that starts with "--" (CONV-08); returns NO when the scan must stop. */
- (BOOL)scanLongOption:(const char*)token {
  const char* name = token + 2;
  const char* equals = strchr(name, '=');
  size_t length = equals != NULL ? (size_t)(equals - name) : strlen(name);

  for (NSUInteger index = 0; index < 2; index++) {
    const DPHValueOption* option = kValueOptions[index];
    if (LongNameIs(name, length, option->longSpelling)) {
      const char* value = equals != NULL ? equals + 1 : [self takeNextToken];
      if (value == NULL) {
        return [self failWithKind:DPHLongMissingValue
                          subject:option->longSpelling
                           length:strlen(option->longSpelling)];
      }
      [self storeValue:value option:index spelling:option->longSpelling];
      return YES;
    }
  }

  for (NSUInteger index = 0; index < sizeof kFlagOptions / sizeof kFlagOptions[0]; index++) {
    const DPHFlagOption* flag = &kFlagOptions[index];
    if (LongNameIs(name, length, flag->spelling)) {
      if (equals != NULL) {
        return [self failWithKind:DPHLongUnexpectedValue
                          subject:flag->spelling
                           length:strlen(flag->spelling)];
      }
      _action = flag->action;
      return NO;
    }
  }

  /* No abbreviations: anything else is unrecognized, quoted whole (CONV-13). */
  return [self failWithKind:DPHUnrecognizedOption subject:token length:strlen(token)];
}

/*
 * Handles a token such as "-c2" or "-n" (CONV-07). Both short options take a value, so the
 * first letter of a bundle always consumes the rest of the token (or the next token).
 */
- (BOOL)scanShortOption:(const char*)token {
  const char* letter = token + 1;
  for (NSUInteger index = 0; index < 2; index++) {
    const DPHValueOption* option = kValueOptions[index];
    if (*letter == option->letter) {
      const char* value = letter[1] != '\0' ? letter + 1 : [self takeNextToken];
      if (value == NULL) {
        return [self failWithKind:DPHShortMissingValue subject:letter length:1];
      }
      [self storeValue:value option:index spelling:option->shortSpelling];
      return YES;
    }
  }
  return [self failWithKind:DPHInvalidOption subject:letter length:UTF8CharacterLength(letter)];
}

- (DPHParsedArguments*)scan {
  const char* firstOperand = NULL;
  BOOL optionsEnded = NO;
  BOOL keepScanning = YES;
  while (keepScanning && _next < _count) {
    const char* token = [self takeNextToken];
    if (!optionsEnded && strcmp(token, "--") == 0) {
      optionsEnded = YES; /* CONV-09: every later token is an operand. */
    } else if (!optionsEnded && strncmp(token, "--", 2) == 0) {
      keepScanning = [self scanLongOption:token];
    } else if (!optionsEnded && token[0] == '-' && token[1] != '\0') {
      keepScanning = [self scanShortOption:token];
    } else if (firstOperand == NULL) {
      firstOperand = token; /* Operands are only collected during the scan (CONV-12). */
    }
  }
  /* dp-hello accepts no operands (FR-09); checked after the scan, so --help still wins. */
  if (_action == DPHActionGreet && firstOperand != NULL) {
    [self failWithKind:DPHExtraOperand subject:firstOperand length:strlen(firstOperand)];
  }
  return [[[DPHParsedArguments alloc] initWithAction:_action
                                           nameValue:_values[0]
                                          nameOption:_options[0]
                                          countValue:_values[1]
                                         countOption:_options[1]
                                               error:_error] autorelease];
}

@end

@implementation DPHCommandLine

+ (DPHParsedArguments*)parseArguments:(const char* const*)arguments count:(NSUInteger)count {
  DPHScanner* scanner = [[[DPHScanner alloc] initWithTokens:arguments count:count] autorelease];
  return [scanner scan];
}

@end
