#import "DPHApplication.h"

#include <string.h>

#import "DPHCommandLine.h"
#import "DPHGreeting.h"
#import "DPHProgram.h"
#import "DPHUsageError.h"
#import "DPHValidation.h"

const char DPHHelpText[] =
    "Usage: " DPH_PROGRAM_NAME " [OPTION]...\n"
    "Print a greeting to standard output.\n"
    "\n"
    "Options:\n"
    "  -n, --name=NAME     greet NAME instead of World\n"
    "  -c, --count=COUNT   print the greeting COUNT times (1-1000, default 1)\n"
    "      --help          display this help and exit\n"
    "      --version       output version information and exit\n";

const char DPHVersionText[] = DPH_PROGRAM_NAME " (dialectic-playground) " DPH_PROGRAM_VERSION "\n";

@implementation DPHOutcome

+ (id)outcomeWithOutput:(NSData*)output error:(NSData*)error status:(int)status {
  DPHOutcome* outcome = [[[self alloc] init] autorelease];
  outcome->_standardOutput = [output copy];
  outcome->_standardError = [error copy];
  outcome->_status = status;
  return outcome;
}

- (void)dealloc {
  [_standardOutput release];
  [_standardError release];
  [super dealloc];
}

- (NSData*)standardOutput {
  return _standardOutput;
}

- (NSData*)standardError {
  return _standardError;
}

- (int)status {
  return _status;
}

@end

static DPHOutcome* Success(NSData* output) {
  return [DPHOutcome outcomeWithOutput:output error:[NSData data] status:DPHExitSuccess];
}

static DPHOutcome* Text(const char* text) {
  return Success([NSData dataWithBytes:text length:strlen(text)]);
}

static DPHOutcome* UsageFailure(DPHUsageError* error) {
  return [DPHOutcome outcomeWithOutput:[NSData data] error:[error diagnostic] status:DPHExitUsage];
}

@implementation DPHApplication

+ (DPHOutcome*)runWithArguments:(const char* const*)arguments count:(NSUInteger)count {
  DPHParsedArguments* parsed = [DPHCommandLine parseArguments:arguments count:count];
  switch ([parsed action]) {
    case DPHActionHelp:
      return Text(DPHHelpText);
    case DPHActionVersion:
      return Text(DPHVersionText);
    case DPHActionUsageError:
      return UsageFailure([parsed error]);
    case DPHActionGreet:
      break;
  }
  DPHUsageError* error = nil;
  DPHGreetingRequest* request = [DPHValidation requestFromArguments:parsed error:&error];
  if (request == nil) {
    return UsageFailure(error);
  }
  NSData* line = [DPHGreeting lineForName:[request name]];
  NSMutableData* output = [NSMutableData dataWithCapacity:[line length] * [request count]];
  for (NSUInteger repetition = 0; repetition < [request count]; repetition++) {
    [output appendData:line];
  }
  return Success(output);
}

@end
