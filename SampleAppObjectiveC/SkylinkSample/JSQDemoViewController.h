//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessages.h"

@class JSQDemoViewController;

@protocol JSQDemoViewControllerDelegate <NSObject>

- (void)didDismissJSQDemoViewController:(JSQDemoViewController *)vc;

@end

@interface JSQDemoViewController : JSQMessagesViewController

@property (unsafe_unretained, nonatomic) BOOL isMinimized;
@property (weak, nonatomic) id<JSQDemoViewControllerDelegate> delegateModal;
@property (copy, nonatomic) NSDictionary *avatars;

@property (strong, nonatomic) NSMutableArray *messages;
@property (weak, nonatomic) NSMutableArray *originalMessageArray;

@property (copy, nonatomic) NSString *chatNick;
@property (copy, nonatomic) NSString *peerId;

@property (strong, nonatomic) UIImageView *incomingBubbleImageView;
@property (strong, nonatomic) UIImageView *outgoingBubbleImageView;

- (void)closePressed:(UIBarButtonItem *)sender;
- (void)highlightPanelButton;
- (void)receiveMessage:(NSString*)message nick:(NSString*)nick;
- (void)receiveMessagePressed:(UIBarButtonItem *)sender;
- (void)setupModel:(NSMutableArray*)messageArray;
- (void)setupTestModel;

@end
