//
//  MyDocument.h
//  NSDocumentDemo
//
//  Created by Allan on 2018/1/11.
//  Copyright © 2018年 Allan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TestDocumentWindowController.h"

@interface MyDocument : NSDocument
@property(nonatomic,strong)TestDocumentWindowController *testVC;
@property(nonatomic,strong)NSTextStorage *textStorage;
@property(nonatomic,copy) NSString *fileTypeToSet;
@property(nonatomic,assign)BOOL transient;
@property(nonatomic,assign)NSStringEncoding encoding;
@property(nonatomic,assign)BOOL openedIgnoringRichText;
@property(nonatomic,assign)BOOL convertedDocument;         /* Converted (or filtered) from some other format (and hence not writable) */
@property(nonatomic,assign)BOOL lossyDocument;             /* Loaded lossily, so might not be a good idea to overwrite */
@property(nonatomic,assign)BOOL hasMultiplePages;          /* Whether the document prefers a paged display */
@property(nonatomic,assign)BOOL isReadOnly;
@property(nonatomic,assign)CGFloat scaleFactor;             /* The scale factor retreived from file */
@property(nonatomic,assign)NSSize viewSize;                 /* The view size, as stored in an RTF document. Can be NSZeroSize */
@property(nonatomic,assign)NSSize paperSize;
@property(nonatomic,assign)CGFloat hyphenationFactor;       /* Hyphenation factor (0.0-1.0, 0.0 == disabled) */
@property(nonatomic,strong)NSColor *backgroundColor;        /* The color of the document's background */


- (BOOL)isTransientAndCanBeReplaced ;

- (void)applyDefaultTextAttributes:(BOOL)forRichText;

- (BOOL)isOpenedIgnoringRichText;

- (NSDictionary *)documentPropertyToAttributeNameMappings;

@end
