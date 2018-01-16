//
//  TestDocumentWindowController.m
//  NSDocumentDemo
//
//  Created by Allan on 2018/1/12.
//  Copyright © 2018年 Allan. All rights reserved.
//

#import "TestDocumentWindowController.h"
#import "MyDocument.h"
@interface TestDocumentWindowController ()

@end

@implementation TestDocumentWindowController

- (id)init{
    if (self = [super initWithWindowNibName:@"TestDocumentWindowController"]) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
//    [self.document readFileWrapper];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSLog(@"document = %@",self.document);
    NSTextStorage *textStrage = [self.document textStorage];
    [self.textView setString:textStrage.string];
    
}

@end
