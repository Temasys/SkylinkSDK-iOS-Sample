//
//  DataTransferViewController.m
//  SkylinkSample
//
//  Created by Romain Pellen on 08/06/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "DataTransferViewController.h"

#define ROOM_NAME  @"DATA-TRANSFER-ROOM"

@interface DataTransferViewController ()
@property (strong, nonatomic) SKYLINKConnection *skylinkConnection;
@property (weak, nonatomic) IBOutlet UIView *localColorView;
@property (weak, nonatomic) IBOutlet UISlider *redSlider;
@property (weak, nonatomic) IBOutlet UISlider *greenSlider;
@property (weak, nonatomic) IBOutlet UISlider *blueSlider;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UISwitch *isContinuousSwitch;
@property (weak, nonatomic) IBOutlet UIButton *sendColorButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) NSTimer *timer;

@end

@implementation DataTransferViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Data transfer";
      
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(disconnect)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.dataChannel = YES;
    self.skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config appKey:self.skylinkApiKey];
    self.skylinkConnection.messagesDelegate = self;
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
#ifdef DEBUG
    [SKYLINKConnection setVerbose:TRUE];
#endif
    [self.skylinkConnection connectToRoomWithSecret:self.skylinkApiSecret roomName:ROOM_NAME userInfo:nil];
    
    [self refreshUI];
}

-(void)disconnect {
    if (self.skylinkConnection) [self.skylinkConnection disconnect:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}
-(void)showInfo {
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ infos", NSStringFromClass([self class])] message:[NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", ROOM_NAME, self.skylinkConnection.myPeerId, [self.skylinkApiKey substringFromIndex: [self.skylinkApiKey length] - 7],  [SKYLINKConnection getSkylinkVersion]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark SKYLINKConnectionLifeCycleDelegate
-(void)connection:(SKYLINKConnection *)connection didConnectWithMessage:(NSString *)errorMessage success:(BOOL)isSuccess {
    [self showUIInfo:[NSString stringWithFormat:@"%@ DID CONNECT • success = %@", isSuccess ? @"🔵" : @"🔴", isSuccess ? @"YES" : @"NO"]];
}
#pragma mark SKYLINKConnectionRemotePeerDelegate
-(void)connection:(SKYLINKConnection *)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties *)pmProperties peerId:(NSString *)peerId {
    [self showUIInfo:[NSString stringWithFormat:@"👤 DID JOIN PEER •\npeerID = %@, properties = %@", peerId, pmProperties.description]];
}
-(void)connection:(SKYLINKConnection *)connection didLeavePeerWithMessage:(NSString *)errorMessage peerId:(NSString *)peerId {
    [self showUIInfo:[NSString stringWithFormat:@"✋🏼 DID LEAVE PEER • peerID = %@, message = \n%@", peerId, errorMessage]];
}

#pragma mark SKYLINKConnectionMessagesDelegate

-(void)connection:(SKYLINKConnection *)connection didReceiveBinaryData:(NSData *)data peerId:(NSString *)peerId {
    if (data != nil) {
        NSString *dataType;
        id unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([unarchivedData isKindOfClass:[UIColor class]])
        {
            dataType = @"UIColor";
            self.view.backgroundColor = unarchivedData;
        }
        else if ([unarchivedData isKindOfClass:[UIImage class]])
        {
            dataType = @"UIImage";
            self.imageView.image = unarchivedData;
            [UIView animateWithDuration:1 delay:3 options:0 animations:^(void) {
                self.imageView.alpha = 0;
            }
                             completion:^(BOOL finished) {
                                 self.imageView.image = nil;
                                 self.imageView.alpha = 1;
                             }];
        }
        else {
            dataType = @"OTHER";
        }
        [self showUIInfo:[NSString stringWithFormat:@"Received data of type '%@' and lenght: %lu", dataType, (unsigned long)data.length]];
    }
}

#pragma mark IBActions

-(IBAction)sendDataTap:(UIButton*)sender {
    [self sendCurrentColor];
}
- (IBAction)onAnySliderChange:(UISlider *)sender {
    if (self.isContinuousSwitch.isOn) [self sendCurrentColor];
    [self refreshUI];
}
- (IBAction)isContinuousSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) [self sendCurrentColor];
    [self refreshUI];
}
- (IBAction)sendImageTap:(UIButton *)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dataTransferImage" ofType:@"png" inDirectory:@"DataTransferSamples"];
    UIImage *sampleImage = [UIImage imageWithContentsOfFile:filePath];
    UIImage *sampleImage2 = [UIImage imageWithCGImage:sampleImage.CGImage scale:sampleImage.scale orientation:sampleImage.imageOrientation];
    [self showUIInfo:@"Sending sample image..."];
    [self.skylinkConnection sendBinaryData:[NSKeyedArchiver archivedDataWithRootObject:sampleImage2] peerId:nil];
}
- (IBAction)autoChangeColorSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) {
        NSDate *d = [NSDate dateWithTimeIntervalSinceNow:0.0];
        self.timer = [[NSTimer alloc] initWithFireDate: d
                                              interval: 0.04
                                                target: self
                                              selector:@selector(onTick:)
                                              userInfo:nil repeats:YES];
        
        NSRunLoop *runner = [NSRunLoop currentRunLoop];
        [runner addTimer:self.timer forMode:NSDefaultRunLoopMode];
    }
    else {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark Utils

-(void)refreshUI {
    self.localColorView.backgroundColor = [self slidersUIColor];
    self.sendColorButton.hidden = self.isContinuousSwitch.isOn;
}

-(void)onTick:(NSTimer *)timer {
    float increment = 0.004;
    self.redSlider.value   = (self.redSlider.value   + increment > 1)       ? 0 : self.redSlider.value   + increment;
    self.greenSlider.value = (self.greenSlider.value + 1.9 * increment > 1) ? 0 : self.greenSlider.value + 1.9 * increment;
    self.blueSlider.value  = (self.blueSlider.value  + 3.1 * increment > 1) ? 0 : self.blueSlider.value  + 3.1 * increment;
    if (self.isContinuousSwitch.isOn) [self sendCurrentColor];
    [self refreshUI];
}

-(void)sendCurrentColor {
    [self showUIInfo:@"Sending current local color..."];
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:[self slidersUIColor]];
    [self.skylinkConnection sendBinaryData:colorData peerId:nil];
}

-(void)showUIInfo:(NSString *)infoMessage {
    self.infoTextView.text = [NSString stringWithFormat:@"[%.3f] %@\n%@", CFAbsoluteTimeGetCurrent(), infoMessage, self.infoTextView.text];
}

-(UIColor *)slidersUIColor {
    return [UIColor colorWithRed:self.redSlider.value green:self.greenSlider.value blue:self.blueSlider.value alpha:1.0];
}


@end




