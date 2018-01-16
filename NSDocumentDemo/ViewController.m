//
//  ViewController.m
//  NSDocumentDemo
//
//  Created by Allan on 2018/1/11.
//  Copyright © 2018年 Allan. All rights reserved.
//

#import "ViewController.h"
#import "MyDocumentController.h"
#import "MyDocument.h"
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}
- (IBAction)showDocument:(id)sender {
    NSString *path=[[NSBundle mainBundle] pathForResource:@"Text1" ofType:@"rtf"];
//    path = @"/Users/allan/Desktop/testTest.rtf";
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
//    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileUrl display:YES
//                                                                 completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
//                                                                     NSLog(@"error = %@",error);
//                                                                 }];
    MyDocument *document = [[MyDocument alloc] initWithContentsOfURL:fileUrl ofType:@"rtfd" error:nil];
    [document makeWindowControllers];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
