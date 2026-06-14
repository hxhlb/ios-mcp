#import "ClipboardManager.h"
#import "MCPLogger.h"
#import <UIKit/UIKit.h>

#define CLIPBOARD_LOG(fmt, ...) do { \
    if ([MCPLogger isDebugLoggingEnabled]) { \
        NSString *_iosmcp_log = [NSString stringWithFormat:(@"[Clipboard] " fmt), ##__VA_ARGS__]; \
        NSLog(@"[witchan][ios-mcp]%@", _iosmcp_log); \
        [MCPLogger logMessage:_iosmcp_log]; \
    } \
} while (0)

@implementation ClipboardManager

+ (instancetype)sharedInstance {
    static ClipboardManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ClipboardManager alloc] init];
    });
    return instance;
}

- (NSDictionary *)readClipboard {
    __block NSDictionary *result;
    dispatch_block_t block = ^{
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        NSMutableDictionary *info = [NSMutableDictionary dictionary];

        info[@"text"] = pb.string ?: [NSNull null];
        info[@"hasImage"] = @(pb.hasImages);
        info[@"hasURL"] = @(pb.hasURLs);

	        if (pb.hasURLs) {
	            info[@"url"] = pb.URL.absoluteString ?: [NSNull null];
	        }

        CLIPBOARD_LOG(@"Read clipboard hasText=%@ hasImage=%@ hasURL=%@",
                      pb.string.length > 0 ? @"yes" : @"no",
                      pb.hasImages ? @"yes" : @"no",
                      pb.hasURLs ? @"yes" : @"no");
        result = [info copy];
    };

    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    return result;
}

- (BOOL)writeText:(NSString *)text {
    if (!text) return NO;

    __block BOOL ok = NO;
    dispatch_block_t block = ^{
        [UIPasteboard generalPasteboard].string = text;
        ok = YES;
        CLIPBOARD_LOG(@"Wrote clipboard textChars=%lu", (unsigned long)text.length);
    };

    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    return ok;
}

@end
