//
//  ReloadWebSocket.h
//  ProtoKit
//
//  Created by Michael Feldstein on 8/21/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "WebSocket.h"
#import "MyHTTPConnection.h"

@interface ReloadWebSocket : WebSocket

@property BOOL connected;
@property MyHTTPConnection* connection;

@end
