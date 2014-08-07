#import "MyHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPLogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


@implementation MyHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	// Use HTTPConnection's filePathForURI method.
	// This method takes the given path (which comes directly from the HTTP request),
	// and converts it to a full path by combining it with the configured document root.
	// 
	// It also does cool things for us like support for converting "/" to "/index.html",
	// and security restrictions (ensuring we don't serve documents outside configured document root folder).
	
	NSString *filePath = [self filePathForURI:path];
	
	// Convert to relative path
	
	NSString *documentRoot = [config documentRoot];
	
	if (![filePath hasPrefix:documentRoot])
	{
		// Uh oh.
		// HTTPConnection's filePathForURI was supposed to take care of this for us.
		return nil;
	}
	
	NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
	
	if ([relativePath isEqualToString:@"/list"])
	{
		HTTPLogVerbose(@"%@[%p]: Serving up dynamic content", THIS_FILE, self);
		NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[@"~/Prototypes" stringByExpandingTildeInPath] error:nil];
        NSString* filter = @"!%K BEGINSWITH %@";
        NSPredicate* predicate = [NSPredicate predicateWithFormat:filter, @"self", @"."];
        dirFiles = [dirFiles filteredArrayUsingPredicate:predicate];
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dirFiles
                                                           options:NSJSONWritingPrettyPrinted error:nil];
		return [[HTTPDataResponse alloc] initWithData:jsonData];
	}
	
	return [super httpResponseForMethod:method URI:path];
}

@end
