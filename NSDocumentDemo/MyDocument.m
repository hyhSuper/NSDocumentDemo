//
//  MyDocument.m
//  NSDocumentDemo
//
//  Created by Allan on 2018/1/11.
//  Copyright © 2018年 Allan. All rights reserved.
//

#import "MyDocument.h"
#import "MyDocumentController.h"

#define TabWidth @"TabWidth"
#define oldEditPaddingCompensation 12.0

NSString *SimpleTextType = @"com.apple.traditional-mac-plain-text";
NSString *Word97Type = @"com.microsoft.word.doc";
NSString *Word2007Type = @"org.openxmlformats.wordprocessingml.document";
NSString *Word2003XMLType = @"com.microsoft.word.wordml";
NSString *OpenDocumentTextType = @"org.oasis-open.opendocument.text";

@implementation MyDocument

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"TestDocumentWindowController";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    
    
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;
}
- (void)makeWindowControllers{
    TestDocumentWindowController *vc = [[TestDocumentWindowController alloc]initWithWindowNibName:@"TestDocumentWindowController"];
    [self addWindowController:vc];
//    [MyDocumentController sharedDocumentController]
    //    [vc.window makeMainWindow];
    
}

//- (void)setText:(NSAttributedString*)fileContents{
//    [self.testVC.textView setString:fileContents];
//}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSLog(@"data.length= %ld",data.length);

    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return NO;
}

- (BOOL)readFromURL:(NSURL *)inAbsoluteURL ofType:(NSString *)inTypeName
              error:(NSError **)outError {
    MyDocumentController *docController = (MyDocumentController*)[MyDocumentController sharedDocumentController];
    NSMutableAttributedString *fileContents = [[NSMutableAttributedString alloc]
                                        initWithURL:inAbsoluteURL options:NULL
                                        documentAttributes:NULL error:outError];
    
    NSTextStorage *text = [[NSTextStorage alloc] initWithAttributedString:fileContents];
    [self setTextStorage:text];
    BOOL readSuccess = [self readFromURL:inAbsoluteURL ofType:inTypeName encoding:NSUTF8StringEncoding ignoreRTF:NO ignoreHTML:YES error:outError];

//    if (fileContents) {
//        readSuccess = YES;
//
////        self.testVC.textView setsst
//        NSLog(@"fileContents = %@",fileContents);
//    }
//    if (readSuccess) {
//        [docController displayDocument:self];
//    }
    return readSuccess;
}
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName encoding:(NSStringEncoding)encoding ignoreRTF:(BOOL)ignoreRTF ignoreHTML:(BOOL)ignoreHTML error:(NSError **)outError {
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:5];
    NSDictionary *docAttrs;
    id val, paperSizeVal, viewSizeVal;
    NSTextStorage *text = self.textStorage;
    
    /* generalize the passed-in type to a type we support.  for instance, generalize "public.xml" to "public.txt" */
    typeName = [[self class] readableTypeForType:typeName];
    
    
    [[self undoManager] disableUndoRegistration];
    [options setObject:absoluteURL forKey:NSBaseURLDocumentOption];
    [self setEncoding:encoding];
    
    // Check type to see if we should load the document as plain. Note that this check isn't always conclusive, which is why we do another check below, after the document has been loaded (and correctly categorized).
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    if ((ignoreRTF && ([workspace type:typeName conformsToType:(NSString *)kUTTypeRTF] || [workspace type:typeName conformsToType:Word2003XMLType])) || (ignoreHTML && [workspace type:typeName conformsToType:(NSString *)kUTTypeHTML]) || self.openedIgnoringRichText) {
        [options setObject:NSPlainTextDocumentType forKey:NSDocumentTypeDocumentOption]; // Force plain
        typeName = (NSString *)kUTTypeText;
        [self setOpenedIgnoringRichText:YES];
    }
    
    [[text mutableString] setString:@""];
    // Remove the layout managers while loading the text; mutableCopy retains the array so the layout managers aren't released
    NSMutableArray *layoutMgrs = [[text layoutManagers] mutableCopy];
    NSEnumerator *layoutMgrEnum = [layoutMgrs objectEnumerator];
    NSLayoutManager *layoutMgr = nil;
    while ((layoutMgr = [layoutMgrEnum nextObject])) [text removeLayoutManager:layoutMgr];
    
    // We can do this loop twice, if the document is loaded as rich text although the user requested plain
    BOOL retry;
    do {
        BOOL success;
        NSString *docType;
        
        retry = NO;
        
        [text beginEditing];
        success = [text readFromURL:absoluteURL options:options documentAttributes:&docAttrs error:outError];
        
        if (!success) {
            [text endEditing];
            layoutMgrEnum = [layoutMgrs objectEnumerator]; // rewind
            while ((layoutMgr = [layoutMgrEnum nextObject])) [text addLayoutManager:layoutMgr];   // Add the layout managers back
            return NO;    // return NO on error; outError has already been set
        }
        
        docType = [docAttrs objectForKey:NSDocumentTypeDocumentAttribute];
        
        // First check to see if the document was rich and should have been loaded as plain
        if (![[options objectForKey:NSDocumentTypeDocumentOption] isEqualToString:NSPlainTextDocumentType] && ((ignoreHTML && [docType isEqual:NSHTMLTextDocumentType]) || (ignoreRTF && ([docType isEqual:NSRTFTextDocumentType] || [docType isEqual:NSWordMLTextDocumentType])))) {
            [text endEditing];
            [[text mutableString] setString:@""];
            [options setObject:NSPlainTextDocumentType forKey:NSDocumentTypeDocumentOption];
            typeName = (NSString *)kUTTypeText;
            [self setOpenedIgnoringRichText:YES];
            retry = YES;
        } else {
            NSString *newFileType = [[self textDocumentTypeToTextEditDocumentTypeMappingTable] objectForKey:docType];
            if (newFileType) {
                typeName = newFileType;
            } else {
                typeName = (NSString *)kUTTypeRTF; // Hmm, a new type in the Cocoa text system. Treat it as rich. ??? Should set the converted flag too?
            }
            if (![[self class] isRichTextType:typeName]) [self applyDefaultTextAttributes:NO];
            [text endEditing];
        }
    } while(retry);
    
    [self setFileType:typeName];
    // If we're reverting, NSDocument will set the file type behind out backs. This enables restoring that type.
    self.fileTypeToSet = [typeName copy];
    layoutMgrEnum = [layoutMgrs objectEnumerator]; // rewind
    while ((layoutMgr = [layoutMgrEnum nextObject])) [text addLayoutManager:layoutMgr];   // Add the layout managers back
    
    val = [docAttrs objectForKey:NSCharacterEncodingDocumentAttribute];
    [self setEncoding:(val ? [val unsignedIntegerValue] : NSUTF8StringEncoding)];
    
    if ((val = [docAttrs objectForKey:NSConvertedDocumentAttribute])) {
        [self setConvertedDocument:([val integerValue] > 0)];    // Indicates filtered
        [self setLossyDocument:([val integerValue] < 0)];    // Indicates lossily loaded
    }
    
    /* If the document has a stored value for view mode, use it. Otherwise wrap to window. */
    if ((val = [docAttrs objectForKey:NSViewModeDocumentAttribute])) {
        [self setHasMultiplePages:([val integerValue] == 1)];
        if ((val = [docAttrs objectForKey:NSViewZoomDocumentAttribute])) {
            [self setScaleFactor:([val doubleValue] / 100.0)];
        }
    } else [self setHasMultiplePages:NO];
    
//    [self willChangeValueForKey:@"printInfo"];
//    if ((val = [docAttrs objectForKey:NSLeftMarginDocumentAttribute])) [[self printInfo] setLeftMargin:[val doubleValue]];
//    if ((val = [docAttrs objectForKey:NSRightMarginDocumentAttribute])) [[self printInfo] setRightMargin:[val doubleValue]];
//    if ((val = [docAttrs objectForKey:NSBottomMarginDocumentAttribute])) [[self printInfo] setBottomMargin:[val doubleValue]];
//    if ((val = [docAttrs objectForKey:NSTopMarginDocumentAttribute])) [[self printInfo] setTopMargin:[val doubleValue]];
//    [self didChangeValueForKey:@"printInfo"];
    
    /* Pre MacOSX versions of TextEdit wrote out the view (window) size in PaperSize.
     If we encounter a non-MacOSX RTF file, and it's written by TextEdit, use PaperSize as ViewSize */
    viewSizeVal = [docAttrs objectForKey:NSViewSizeDocumentAttribute];
    paperSizeVal = [docAttrs objectForKey:NSPaperSizeDocumentAttribute];
    if (paperSizeVal && NSEqualSizes([paperSizeVal sizeValue], NSZeroSize)) paperSizeVal = nil;    // Protect against some old documents with 0 paper size
    
    if (viewSizeVal) {
        [self setViewSize:[viewSizeVal sizeValue]];
        if (paperSizeVal) [self setPaperSize:[paperSizeVal sizeValue]];
    } else {    // No ViewSize...
        if (paperSizeVal) {    // See if PaperSize should be used as ViewSize; if so, we also have some tweaking to do on it
            val = [docAttrs objectForKey:NSCocoaVersionDocumentAttribute];
            if (val && ([val integerValue] < 100)) {    // Indicates old RTF file; value described in AppKit/NSAttributedString.h
                NSSize size = [paperSizeVal sizeValue];
                if (size.width > 0 && size.height > 0 && ![self hasMultiplePages]) {
                    size.width = size.width - oldEditPaddingCompensation;
                    [self setViewSize:size];
                }
            } else {
                [self setPaperSize:[paperSizeVal sizeValue]];
            }
        }
    }
    
    [self setHyphenationFactor:(val = [docAttrs objectForKey:NSHyphenationFactorDocumentAttribute]) ? [val floatValue] : 0];
    [self setBackgroundColor:(val = [docAttrs objectForKey:NSBackgroundColorDocumentAttribute]) ? val : [NSColor whiteColor]];
    
    // Set the document properties, generically, going through key value coding
//    NSDictionary *map = [self documentPropertyToAttributeNameMappings];
//    for (NSString *property in [self knownDocumentProperties]) [self setValue:[docAttrs objectForKey:[map objectForKey:property]] forKey:property];    // OK to set nil to clear
    
    [self setIsReadOnly:((val = [docAttrs objectForKey:NSReadOnlyDocumentAttribute]) && ([val integerValue] > 0))];
    
//    [self setOriginalOrientationSections:[docAttrs objectForKey:NSTextLayoutSectionsAttribute]];
//
//    [self setUsesScreenFonts:[self isRichText] ? [[docAttrs objectForKey:NSUsesScreenFontsDocumentAttribute] boolValue] : YES];
    
    [[self undoManager] enableUndoRegistration];
    
    return YES;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
                     ofType:(NSString *)typeName
                      error:(NSError * _Nullable *)outError{

    return YES;
}

- (BOOL)isTransientAndCanBeReplaced {
    if (!self.transient) return NO;
    for (NSWindowController *controller in [self windowControllers]) if ([[controller window] attachedSheet]) return NO;
    return YES;
}

- (void)setTextStorage:(NSTextStorage *)textStorage{
    // Warning, undo support can eat a lot of memory if a long text is changed frequently
    NSAttributedString *textStorageCopy = [textStorage copy];
    _textStorage = textStorage;
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setTextStorage:) object:textStorageCopy];
    // ts can actually be a string or an attributed string.
//    if ([textStorage isKindOfClass:[NSAttributedString class]]) {
//        [_textStorage replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length]) withAttributedString:textStorage];
//    } else {
//        [[self textStorage] replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length]) withString:textStorage];
//    }

}
- (void)applyDefaultTextAttributes:(BOOL)forRichText{
    NSDictionary *textAttributes = [self defaultTextAttributes:forRichText];
    NSTextStorage *text = [self textStorage];
    // We now preserve base writing direction even for plain text, using the 10.6-introduced attribute enumeration API
    [text enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, [text length]) options:0 usingBlock:^(id paragraphStyle, NSRange paragraphStyleRange, BOOL *stop){
        NSWritingDirection writingDirection = paragraphStyle ? [(NSParagraphStyle *)paragraphStyle baseWritingDirection] : NSWritingDirectionNatural;
        // We also preserve NSWritingDirectionAttributeName (new in 10.6)
        [text enumerateAttribute:NSWritingDirectionAttributeName inRange:paragraphStyleRange options:0 usingBlock:^(id value, NSRange attributeRange, BOOL *stop){
            [text setAttributes:textAttributes range:attributeRange];
            if (value) [text addAttribute:NSWritingDirectionAttributeName value:value range:attributeRange];
        }];
        if (writingDirection != NSWritingDirectionNatural) [text setBaseWritingDirection:writingDirection range:paragraphStyleRange];
    }];
}
- (NSDictionary *)defaultTextAttributes:(BOOL)forRichText {
    static NSParagraphStyle *defaultRichParaStyle = nil;
    NSMutableDictionary *textAttributes = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (forRichText) {
        [textAttributes setObject:[NSFont userFontOfSize:0.0] forKey:NSFontAttributeName];
        if (defaultRichParaStyle == nil) {    // We do this once...
            NSInteger cnt;
            NSString *measurementUnits = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleMeasurementUnits"];
            CGFloat tabInterval = ([@"Centimeters" isEqual:measurementUnits]) ? (72.0 / 2.54) : (72.0 / 2.0);  // Every cm or half inch
            NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
            NSTextTabType type = ((NSWritingDirectionRightToLeft == [NSParagraphStyle defaultWritingDirectionForLanguage:nil]) ? NSRightTabStopType : NSLeftTabStopType);
            [paraStyle setTabStops:[NSArray array]];    // This first clears all tab stops
            for (cnt = 0; cnt < 12; cnt++) {    // Add 12 tab stops, at desired intervals...
                NSTextTab *tabStop = [[NSTextTab alloc] initWithType:type location:tabInterval * (cnt + 1)];
                [paraStyle addTabStop:tabStop];
            }
            defaultRichParaStyle = [paraStyle copy];
        }
        [textAttributes setObject:defaultRichParaStyle forKey:NSParagraphStyleAttributeName];
    } else {
        NSFont *plainFont = [NSFont userFixedPitchFontOfSize:0.0];
        NSFont *charWidthFont = [plainFont screenFontWithRenderingMode:NSFontDefaultRenderingMode];
        NSInteger tabWidth = [[NSUserDefaults standardUserDefaults] integerForKey:TabWidth];
        CGFloat charWidth = [@" " sizeWithAttributes:[NSDictionary dictionaryWithObject:charWidthFont forKey:NSFontAttributeName]].width;
        if (charWidth == 0) charWidth = [charWidthFont maximumAdvancement].width;
        
        // Now use a default paragraph style, but with the tab width adjusted
        NSMutableParagraphStyle *mStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [mStyle setTabStops:[NSArray array]];
        [mStyle setDefaultTabInterval:(charWidth * tabWidth)];
        [textAttributes setObject:[mStyle copy] forKey:NSParagraphStyleAttributeName];
        
        // Also set the font
        [textAttributes setObject:plainFont forKey:NSFontAttributeName];
    }
    return textAttributes;
}

+ (NSString *)readableTypeForType:(NSString *)type {
    // There is a partial order on readableTypes given by UTTypeConformsTo. We linearly extend the partial order to a total order using <.
    // Therefore we can compute the ancestor with greatest level (furthest from root) by linear search in the resulting array.
    // Why do we have to do this?  Because type might conform to multiple readable types, such as "public.rtf" and "public.text" and "public.data"
    // and we want to find the most specialized such type.
    static NSArray *topologicallySortedReadableTypes;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        topologicallySortedReadableTypes = [self readableTypes];
        topologicallySortedReadableTypes = [topologicallySortedReadableTypes sortedArrayUsingComparator:^NSComparisonResult(id type1, id type2) {
            if (type1 == type2) return NSOrderedSame;
            if (UTTypeConformsTo((__bridge CFStringRef)type1, (__bridge CFStringRef)type2)) return NSOrderedAscending;
            if (UTTypeConformsTo((__bridge CFStringRef)type2, ( __bridge CFStringRef)type1)) return NSOrderedDescending;
            return (((NSUInteger)type1 < (NSUInteger)type2) ? NSOrderedAscending : NSOrderedDescending);
        }];
    });
    for (NSString *readableType in topologicallySortedReadableTypes) {
        if (UTTypeConformsTo((__bridge CFStringRef)type, (__bridge CFStringRef)readableType)) return readableType;
    }
    return nil;
}
-(void) setEncoding:(NSStringEncoding)encoding{
    _encoding = encoding;
}

/* Return an NSDictionary which maps Cocoa text system document identifiers (as declared in AppKit/NSAttributedString.h) to document types declared in TextEdit's Info.plist.
 */
- (NSDictionary *)textDocumentTypeToTextEditDocumentTypeMappingTable {
    static NSDictionary *documentMappings = nil;
    // Use of dispatch_once() makes the initialization thread-safe, and it needs to be, since multiple documents can be opened concurrently
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        documentMappings = [[NSDictionary alloc] initWithObjectsAndKeys:
                            (NSString *)kUTTypeText, NSPlainTextDocumentType,
                            (NSString *)kUTTypeRTF, NSRTFTextDocumentType,
                            (NSString *)kUTTypeRTFD, NSRTFDTextDocumentType,
                            SimpleTextType, NSMacSimpleTextDocumentType,
                            (NSString *)kUTTypeHTML, NSHTMLTextDocumentType,
                            Word97Type, NSDocFormatTextDocumentType,
                            Word2007Type, NSOfficeOpenXMLTextDocumentType,
                            Word2003XMLType, NSWordMLTextDocumentType,
                            OpenDocumentTextType, NSOpenDocumentTextDocumentType,
                            (NSString *)kUTTypeWebArchive, NSWebArchiveTextDocumentType,
                            nil];
    });
    return documentMappings;
}
+ (BOOL)isRichTextType:(NSString *)typeName {
    /* We map all plain text documents to public.text.  Therefore a document is rich iff its type is not public.text. */
    return ![typeName isEqualToString:(NSString *)kUTTypeText];
}

- (BOOL)isRichText {
    return [[self class] isRichTextType:[self fileType]];
}
/* Table mapping document property keys "company", etc, to text system document attribute keys (NSCompanyDocumentAttribute, etc)
 */
- (NSDictionary *)documentPropertyToAttributeNameMappings {
    static NSDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                NSCompanyDocumentAttribute, @"company",
                NSAuthorDocumentAttribute, @"author",
                NSKeywordsDocumentAttribute, @"keywords",
                NSCopyrightDocumentAttribute, @"copyright",
                NSTitleDocumentAttribute, @"title",
                NSSubjectDocumentAttribute, @"subject",
                NSCommentDocumentAttribute, @"comment", nil];
    });
    return dict;
}
- (NSArray *)knownDocumentProperties {
    return [[self documentPropertyToAttributeNameMappings] allKeys];
}
@end
