#import "MyHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "AppDelegate.h"
#import "ManifestGenerator.h"
#import "ResourcesGenerator.h"
#import "ReloadWebSocket.h"

@interface MyHTTPConnection () {
    NSMutableArray* _websockets;
}

@end

@implementation MyHTTPConnection

- (id) initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
    self = [super initWithAsyncSocket:newSocket configuration:aConfig];
    _websockets = [NSMutableArray array];
    return self;
}

- (void)sendReload:(NSNotification*)n {
    NSLog(@"Send Reload %@", n);
    for (WebSocket* socket in _websockets) {
        [socket sendMessage:@"reload"];
    }
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
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

- (WebSocket *)webSocketForURI:(NSString *)path
{
    NSLog(@"Web socket for URI: %@", path);
	
	if([path isEqualToString:@"/live-reload"])
	{
		NSLog(@"MyHTTPConnection: Creating MyWebSocket...");
        
		ReloadWebSocket* socket = [[ReloadWebSocket alloc] initWithRequest:request socket:asyncSocket];
        [_websockets addObject:socket];
        socket.connection = self;
        return socket;
	}
	
	return [super webSocketForURI:path];
}

- (void)myWebSocketDidDisconnect:(ReloadWebSocket *)socket {
    NSLog(@"did disconnect");
    [_websockets removeObject:socket];
}

- (void)finalize {
    NSLog(@"Dealloc");
}

@end
