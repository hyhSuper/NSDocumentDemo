//
//  MyDocumentController.m
//  NSDocumentDemo
//
//  Created by Allan on 2018/1/11.
//  Copyright © 2018年 Allan. All rights reserved.
//

#import "MyDocumentController.h"
#import "TextEditErrors.h"

@implementation MyDocumentController

- (MyDocument *)openDocumentWithContentsOfPasteboard:(NSPasteboard *)pb display:(BOOL)display error:(NSError **)error{
    NSString *pasteboardType = [pb availableTypeFromArray:[NSAttributedString readableTypesForPasteboard:pb]];
    NSData *data = [pb dataForType:pasteboardType];
    NSAttributedString *string = nil;
    NSString *type = nil;
    if (data != nil) {
        NSDictionary *attributes = nil;
        string = [[NSAttributedString alloc] initWithData:data options:nil documentAttributes:&attributes error:error];
        // We only expect to see plain-text, RTF, and RTFD at this point.
        NSString *docType = [attributes objectForKey:NSDocumentTypeDocumentAttribute];
        if ([docType isEqualToString:NSPlainTextDocumentType]) {
            type = (NSString *)kUTTypeText;
        } else if ([docType isEqualToString:NSRTFTextDocumentType]) {
            type = (NSString *)kUTTypeRTF;
        } else if ([docType isEqualToString:NSRTFDTextDocumentType]) {
            type = (NSString *)kUTTypeRTFD;
        }
    }
    
    if (string != nil && type != nil) {
        Class docClass = [self documentClassForType:type];
        
        if (docClass != nil) {
            MyDocument *transientDoc = nil;
            
            [_transientDocumentLock lock];
            transientDoc = [self transientDocumentToReplace];
            if (transientDoc) {
                // If this document has claimed the transient document, cause -transientDocumentToReplace to return nil for all other documents.
                [transientDoc setTransient:NO];
            }
            [_transientDocumentLock unlock];
            
            id doc = [[docClass alloc] initWithType:type error:error];
            if (!doc) return nil; // error has been set
            NSTextStorage *text = [doc textStorage];
            [text replaceCharactersInRange:NSMakeRange(0, [text length]) withAttributedString:string];
            if ([type isEqualToString:(NSString *)kUTTypeText]) [doc applyDefaultTextAttributes:NO];
            
            [self addDocument:doc];
            [doc updateChangeCount:NSChangeReadOtherContents];
            
            if (transientDoc) [self replaceTransientDocument:[NSArray arrayWithObjects:transientDoc, doc, nil]];
            if (display) [self displayDocument:doc];
            
            return doc;
        }
    }
    
    // Either we could not read data from pasteboard, or the data was interpreted with a type we don't understand.
    if ((data == nil || (string != nil && type == nil)) && error) *error = [NSError errorWithDomain:TextEditErrorDomain code:TextEditOpenDocumentWithSelectionServiceFailed userInfo:[
                                                                                                                                                                                      NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Service failed. Couldn\\U2019t open the selection.", @"Title of alert indicating error during 'New Window Containing Selection' service"), NSLocalizedDescriptionKey,
                                                                                                                                                                                      NSLocalizedString(@"There might be an internal error or a performance problem, or the source application may be providing text of invalid type in the service request. Please try the operation a second time. If that doesn\\U2019t work, copy/paste the selection into TextEdit.", @"Recommendation when 'New Window Containing Selection' service fails"), NSLocalizedRecoverySuggestionErrorKey,
                                                                                                                                                                                      nil]];
    
    return nil;
}

- (void)displayDocument:(NSDocument *)doc {
    // Documents must be displayed on the main thread.
    if ([NSThread isMainThread]) {
        [doc makeWindowControllers];
        [doc showWindows];
    } else {
        [self performSelectorOnMainThread:_cmd withObject:doc waitUntilDone:YES];
    }
}

- (void)replaceTransientDocument:(NSArray *)documents {
    // Transient document must be replaced on the main thread, since it may undergo automatic display on the main thread.
    if ([NSThread isMainThread]) {
        NSDocument *transientDoc = [documents objectAtIndex:0], *doc = [documents objectAtIndex:1];
        NSArray *controllersToTransfer = [[transientDoc windowControllers] copy];
        NSEnumerator *controllerEnum = [controllersToTransfer objectEnumerator];
        NSWindowController *controller;
        
        while (controller = [controllerEnum nextObject]) {
            [doc addWindowController:controller];
            [transientDoc removeWindowController:controller];
        }
        [transientDoc close];
        
        
        // We replaced the value of the transient document with opened document, need to notify accessibility clients.
        for (NSLayoutManager *layoutManager in [[(MyDocument *)doc textStorage] layoutManagers]) {
            for (NSTextContainer *textContainer in [layoutManager textContainers]) {
                NSTextView *textView = [textContainer textView];
                if (textView) NSAccessibilityPostNotification(textView, NSAccessibilityValueChangedNotification);
            }
        }
        
    } else {
        [self performSelectorOnMainThread:_cmd withObject:documents waitUntilDone:YES];
    }
}
/* This method is overridden in order to support transient documents, i.e. the automatic closing of an automatically created untitled document, when a real document is opened.
 */
- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
    MyDocument *doc = [super openUntitledDocumentAndDisplay:displayDocument error:outError];
    
    if (!doc) return nil;
    
    if ([[self documents] count] == 1) {
        // Determine whether this document might be a transient one
        // Check if there is a current AppleEvent. If there is, check whether it is an open or reopen event. In that case, the document being created is transient.
        NSAppleEventDescriptor *evtDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        AEEventID evtID = [evtDesc eventID];
        
        if (evtDesc && (evtID == kAEReopenApplication || evtID == kAEOpenApplication) && [evtDesc eventClass] == kCoreEventClass) {
            [doc setTransient:YES];
        }
    }
    
    return doc;
}


- (MyDocument *)transientDocumentToReplace {
    NSArray *documents = [self documents];
    MyDocument *transientDoc = nil;
    return ([documents count] == 1 && [(transientDoc = [documents objectAtIndex:0]) isTransientAndCanBeReplaced]) ? transientDoc : nil;
}
- (NSStringEncoding)lastSelectedEncodingForURL:(NSURL *)url{
    return NSUTF8StringEncoding;
}
- (BOOL)lastSelectedIgnoreHTMLForURL:(NSURL *)url{
    return YES;
}
- (BOOL)lastSelectedIgnoreRichForURL:(NSURL *)url{
    return YES;
}

@end
