//
//  MyDocumentController.h
//  NSDocumentDemo
//
//  Created by Allan on 2018/1/11.
//  Copyright © 2018年 Allan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"
@interface MyDocumentController : NSDocumentController{
    NSLock *_transientDocumentLock;
    NSLock *_displayDocumentLock;

}

- (MyDocument *)openDocumentWithContentsOfPasteboard:(NSPasteboard *)pb display:(BOOL)display error:(NSError **)error;

- (NSStringEncoding)lastSelectedEncodingForURL:(NSURL *)url;

- (BOOL)lastSelectedIgnoreHTMLForURL:(NSURL *)url;

- (BOOL)lastSelectedIgnoreRichForURL:(NSURL *)url;

- (void)displayDocument:(NSDocument *)doc;

@end
