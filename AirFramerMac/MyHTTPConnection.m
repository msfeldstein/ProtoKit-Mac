#import "MyHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "AppDelegate.h"
#import "ManifestGenerator.h"

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
        AppDelegate* appDel = (AppDelegate*)[NSApplication sharedApplication].delegate;
        NSString* directory = appDel.folder.path;
        NSError* err;
		NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&err];
        if (err) {
            NSLog(@"Error opening directory %@", err);
            return [[HTTPDataResponse alloc] initWithData:[@"[]" dataUsingEncoding:NSASCIIStringEncoding]];
        }
        NSString* filter = @"!%K BEGINSWITH %@";
        NSPredicate* predicate = [NSPredicate predicateWithFormat:filter, @"self", @"."];
        dirFiles = [dirFiles filteredArrayUsingPredicate:predicate];
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dirFiles
                                                           options:NSJSONWritingPrettyPrinted error:nil];
		return [[HTTPDataResponse alloc] initWithData:jsonData];
	} else if ([[path lastPathComponent] isEqualToString:@"airframe.appcache"]) {
        ManifestGenerator* generator = [ManifestGenerator new];
        NSString* manifest = [generator generateManifest:[filePath stringByDeletingLastPathComponent]];
        return [[HTTPDataResponse alloc] initWithData:[manifest dataUsingEncoding:NSASCIIStringEncoding]];
    } else if ([[path lastPathComponent] isEqualToString:@"cached-index.html"]) {
        filePath = [filePath stringByReplacingOccurrencesOfString:@"cached-" withString:@""];
        NSString* html = [NSString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error:nil];
        html = [html stringByReplacingOccurrencesOfString:@"<html>" withString:@"<html manifest=\"airframe.appcache\">"];
        return [[HTTPDataResponse alloc] initWithData:[html dataUsingEncoding:NSASCIIStringEncoding]];
    }
	
	return [super httpResponseForMethod:method URI:path];
}


@end
