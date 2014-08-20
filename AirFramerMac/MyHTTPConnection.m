#import "MyHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "AppDelegate.h"
#import "ManifestGenerator.h"
#import "ResourcesGenerator.h"

@implementation MyHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSLog(@"HTTP Path %@", path);
	NSString *filePath = [self filePathForURI:path];
    NSString *documentRoot = [config documentRoot];
	if (![filePath hasPrefix:documentRoot])
	{
		return nil;
	}
	
	NSString* relativePath = [filePath substringFromIndex:[documentRoot length]];
    NSString* projectPath = [filePath stringByDeletingLastPathComponent];
    AppDelegate* appDel = (AppDelegate*)[NSApplication sharedApplication].delegate;
    NSString* workspaceDirectory = appDel.folder.path;
	
    if ([relativePath isEqualToString:@"/list"])
	{
        
        NSError* err;
		NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workspaceDirectory error:&err];
        if (err) {
            NSLog(@"Error opening directory %@", err);
            return [[HTTPDataResponse alloc] initWithData:[@"[]" dataUsingEncoding:NSASCIIStringEncoding]];
        }
        NSMutableArray* directoriesWithIndex = [NSMutableArray array];
        for (NSString* directory in dirFiles) {
            NSString* indexPath = [[workspaceDirectory stringByAppendingPathComponent:directory] stringByAppendingPathComponent:@"index.html"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:indexPath]) {
                [directoriesWithIndex addObject:directory];
            }
        }
        NSString* filter = @"!%K BEGINSWITH %@";
        NSPredicate* predicate = [NSPredicate predicateWithFormat:filter, @"self", @"."];
        NSArray* finalDirectories = [directoriesWithIndex filteredArrayUsingPredicate:predicate];
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:finalDirectories
                                                           options:NSJSONWritingPrettyPrinted error:nil];
		return [[HTTPDataResponse alloc] initWithData:jsonData];
    } else if ([[path lastPathComponent] isEqualToString:@"resources.json"]) {
        // TODO (feldstein) cache this until images change
        ResourcesGenerator* generator = [ResourcesGenerator new];
        NSDictionary* resources = [generator generateManifestInProject:projectPath directory:@"images"];
        NSError* err;
        NSData* json = [NSJSONSerialization dataWithJSONObject:resources options:NSJSONWritingPrettyPrinted error:&err];
        if (err) {
            NSLog(@"Error creating json for resource manifest %@", err);
        }
        return [[HTTPDataResponse alloc] initWithData:json];
    } else if ([[path lastPathComponent] isEqualToString:@"scripts.json"]) {
        // TODO (feldstein) cache this until images change
        ResourcesGenerator* generator = [ResourcesGenerator new];
        NSDictionary* resources = [generator generateManifestInProject:projectPath directory:@"scripts"];
        NSError* err;
        NSData* json = [NSJSONSerialization dataWithJSONObject:resources options:NSJSONWritingPrettyPrinted error:&err];
        if (err) {
            NSLog(@"Error creating json for resource manifest %@", err);
        }
        return [[HTTPDataResponse alloc] initWithData:json];
	} else if ([[path lastPathComponent] isEqualToString:@"airframe.appcache"]) {
        ManifestGenerator* generator = [ManifestGenerator new];
        NSLog(@"Proejct Path %@", projectPath);
        NSString* manifest = [generator generateManifest:projectPath];
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
