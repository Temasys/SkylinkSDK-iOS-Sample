//
//  DataTransferViewController.m
//  SkylinkSample
//
//  Created by Temasys on 08/06/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "DataTransferViewController.h"
#import "Constant.h"

//#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_DATATRANSFER"]

@interface DataTransferViewController ()<SKYLINKConnectionMessagesDelegate>
@property (weak, nonatomic) IBOutlet UIView *localColorView;
@property (weak, nonatomic) IBOutlet UISlider *redSlider;
@property (weak, nonatomic) IBOutlet UISlider *greenSlider;
@property (weak, nonatomic) IBOutlet UISlider *blueSlider;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UISwitch *isContinuousSwitch;
@property (weak, nonatomic) IBOutlet UIButton *sendColorButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSTimer *timer;

@end

@implementation DataTransferViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Data Transfer";

    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    [config setAudioVideoSendConfig:AudioVideoConfig_NO_AUDIO_NO_VIDEO];
    [config setAudioVideoReceiveConfig:AudioVideoConfig_NO_AUDIO_NO_VIDEO];
    config.hasDataTransfer = YES;
    _skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config callback:nil];
    _skylinkConnection.messagesDelegate = self;
    _skylinkConnection.lifeCycleDelegate = self;
    _skylinkConnection.remotePeerDelegate = self;
    [_skylinkConnection connectToRoomWithAppKey:APP_KEY secret:APP_SECRET roomName:ROOM_DATA_TRANSFER userData:USER_NAME callback:nil];

    [self refreshUI];
}

#pragma mark SKYLINKConnectionLifeCycleDelegate
- (void)connectionDidConnectToRoomSuccessful:(SKYLINKConnection *)connection
{
    [self showUIInfo:@"DID CONNECT • success "];
    [self.activityIndicator stopAnimating];
}

- (void)connection:(SKYLINKConnection *)connection didConnectToRoomFailed:(NSString *)errorMessage
{
    [self showUIInfo:@"Failed to connect"];
}
#pragma mark SKYLINKConnectionRemotePeerDelegate
- (void)connection:(SKYLINKConnection *)connection didConnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel
{
    [self showUIInfo:[NSString stringWithFormat:@"👤 DID JOIN PEER •\npeerID = %@, properties = %@", remotePeerId, userInfo]];
}

- (void)connection:(SKYLINKConnection *)connection didReceiveRemotePeerLeaveRoom:(NSString *)remotePeerId userInfo:(id)userInfo skylinkInfo:(NSDictionary *)skylinkInfo
{
    [self showUIInfo:[NSString stringWithFormat:@"✋🏼 DID LEAVE PEER • peerID = %@, message = \n%@", remotePeerId, userInfo]];
}
#pragma mark SKYLINKConnectionMessagesDelegate
- (void)connection:(SKYLINKConnection *)connection didReceiveData:(NSData *)data remotePeerId:(NSString *)remotePeerId
{
    if (data != nil) {
        NSString *dataType;
        id unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([unarchivedData isKindOfClass:[UIColor class]]) {
            dataType = @"UIColor";
            self.view.backgroundColor = unarchivedData;
        } else if ([unarchivedData isKindOfClass:[UIImage class]]) {
            dataType = @"UIImage";
            self.imageView.image = unarchivedData;
            [UIView animateWithDuration:1 delay:3 options:0 animations:^(void) {
                self.imageView.alpha = 0;
            } completion:^(BOOL finished) {
                self.imageView.image = nil;
                self.imageView.alpha = 1;
            }];
        } else {
            dataType = @"OTHER";
        }
        [self showUIInfo:[NSString stringWithFormat:@"Received data of type '%@' and lenght: %lu", dataType, (unsigned long)data.length]];
    }
}

#pragma mark IBActions

- (IBAction)sendDataTap:(UIButton*)sender {
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
    [_skylinkConnection sendData:[NSKeyedArchiver archivedDataWithRootObject:sampleImage2] toRemotePeerId:nil callback:^(NSError * _Nullable error) {
        if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
    }];
}
- (IBAction)autoChangeColorSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) {
        NSDate *d = [NSDate dateWithTimeIntervalSinceNow:0.0];
        self.timer = [[NSTimer alloc] initWithFireDate: d interval: 0.04 target: self selector:@selector(onTick:) userInfo:nil repeats:YES];
        NSRunLoop *runner = [NSRunLoop currentRunLoop];
        [runner addTimer:self.timer forMode:NSDefaultRunLoopMode];
    } else {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark Utils

- (void)refreshUI {
    self.localColorView.backgroundColor = [self slidersUIColor];
    self.sendColorButton.hidden = self.isContinuousSwitch.isOn;
}

- (void)onTick:(NSTimer *)timer {
    float increment = 0.004;
    self.redSlider.value = (self.redSlider.value + increment > 1) ? 0 : self.redSlider.value + increment;
    self.greenSlider.value = (self.greenSlider.value + 1.9 * increment > 1) ? 0 : self.greenSlider.value + 1.9 * increment;
    self.blueSlider.value = (self.blueSlider.value + 3.1 * increment > 1) ? 0 : self.blueSlider.value + 3.1 * increment;
    if (self.isContinuousSwitch.isOn) [self sendCurrentColor];
    [self refreshUI];
}

- (void)sendCurrentColor {
    [self showUIInfo:@"Sending current local color..."];
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:[self slidersUIColor]];
    [_skylinkConnection sendData:colorData toRemotePeerId:nil callback:^(NSError * _Nullable error) {
        if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
    }];
}

- (void)showUIInfo:(NSString *)infoMessage {
    self.infoTextView.text = [NSString stringWithFormat:@"[%.3f] %@\n%@", CFAbsoluteTimeGetCurrent(), infoMessage, self.infoTextView.text];
}

- (UIColor *)slidersUIColor {
    return [UIColor colorWithRed:self.redSlider.value green:self.greenSlider.value blue:self.blueSlider.value alpha:1.0];
}


@end




