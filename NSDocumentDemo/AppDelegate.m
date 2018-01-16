//
//  AppDelegate.m
//  NSDocumentDemo
//
//  Created by Allan on 2018/1/11.
//  Copyright © 2018年 Allan. All rights reserved.
//

#import "AppDelegate.h"
#import "TestDocumentWindowController.h"

#import "MyDocumentController.h"
#import "MyDocument.h"
@interface AppDelegate ()
@property (nonatomic,strong)MyDocumentController *mydocumentController;
@property (nonatomic,strong)TestDocumentWindowController *windowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    self.mydocumentController = [MyDocumentController sharedDocumentController];
    self.windowController = [[TestDocumentWindowController alloc] initWithWindowNibName:@"TestDocumentWindowController"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"OpenDocument" object:nil];
//    [mywindowController addDocument: document];

}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (void)handleNotification:(NSNotification*)notification{
    MyDocument *document = notification.object;
    [document addWindowController:self.windowController];
    [self.windowController.window makeMainWindow];
    //    [self.mydocumentController addDocument:document];
//    [self.mydocumentController makeUntitledDocumentOfType:@"rtfd" error:nil];
}

@end
