#import <Foundation/Foundation.h>
#import "HTTPConnection.h"
#import <CocoaHTTPServer/WebSocket.h>

@class ReloadWebSocket;

@interface MyHTTPConnection : HTTPConnection <WebSocketDelegate>

- (void) myWebSocketDidDisconnect:(ReloadWebSocket*)webSocket;
@end
