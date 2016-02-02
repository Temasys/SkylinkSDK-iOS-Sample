//
//  FileTransferViewController.m
//  Skylink_Examples
//
//  Created by Romain Pellen on 18/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "FileTransferViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIAlertView+Blocks.h"
#import <AssetsLibrary/AssetsLibrary.h>


#define ROOM_NAME  @"FILE-TRANSFER-ROOM"


@interface FileTransferViewController ()
// IBOutlets
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoDetailsLabel;


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;


// Other properties
@property (strong, nonatomic) SKYLINKConnection *skylinkConnection;
@property (strong, nonatomic) NSMutableArray *remotePeerArray;
@property (assign, nonatomic) NSNumber *selectedRow;
@end



@implementation FileTransferViewController {
    NSString *transferInProgressPeerId;
    NSString *transferInProgressFilename;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"File transfer";
    self.remotePeerArray = [[NSMutableArray alloc] init];
    
    // Listen to the 'SKYLINKFileProgress' Notification.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressUpdated:) name:@"SKYLINKFileProgress" object:nil];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(disconnect)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.video = NO;
    config.audio = NO;
    config.fileTransfer = YES;
    config.timeout = 30;
    config.dataChannel = YES;
    // Creating SKYLINKConnection
    self.skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config appKey:self.skylinkApiKey];
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.fileTransferDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
    // Connecting to a room
    [SKYLINKConnection setVerbose:TRUE];
    [self.skylinkConnection connectToRoomWithSecret:self.skylinkApiSecret roomName:ROOM_NAME userInfo:nil];
}

-(void)disconnect {
    if (self.skylinkConnection) [self.skylinkConnection disconnect:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

-(void)showInfo {
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ infos", NSStringFromClass([self class])] message:[NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", ROOM_NAME, self.skylinkConnection.myPeerId, [self.skylinkApiKey substringFromIndex: [self.skylinkApiKey length] - 7],  [SKYLINKConnection getSkylinkVersion]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


/**
 @discussion Update progress bar upon getting 'SKYLINKFileProgress' Notification.
 */
- (void)progressUpdated:(NSNotification*)notification {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.infoDetailsLabel.text = [NSString stringWithFormat:@"PeerID: %@\nFilename: %@", notification.userInfo[@"peerId"], transferInProgressFilename];
            float progress = [[notification.userInfo objectForKey:@"percentage"] floatValue];
            if (progress < 1) {
                self.infoLabel.text = @"Transfer in progress...";
                if (transferInProgressPeerId) self.progressView.hidden = NO;
                self.progressView.progress = progress;
            }
            else {
                self.infoLabel.text = @"Transfer completed";
                self.progressView.hidden = YES;
            }
        });
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (section == 0) {
        title = (self.remotePeerArray.count > 0) ? @"Or select a connected peer recipient:" : @"No peer connected yet";
    }
    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.remotePeerArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"];
    cell.textLabel.text = [NSString stringWithFormat:@"Peer %ld, ID: %@", (long)indexPath.row + 1, [self.remotePeerArray objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) ((UITableViewHeaderFooterView *)view).textLabel.textColor = [UIColor lightGrayColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedRow = [NSNumber numberWithInteger:indexPath.row];
    [self showTransferFormForRecipient:self.remotePeerArray[indexPath.row]];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *peerId = nil;
    if (self.selectedRow && [self.selectedRow intValue] < self.remotePeerArray.count) peerId = self.remotePeerArray[[self.selectedRow intValue]];
    [self startFileTransfer:peerId url:info[UIImagePickerControllerReferenceURL] type:SKYLINKAssetTypePhoto];
}

#pragma mark - MPMediaPickerControllerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
    NSString *peerId = nil;
    if (self.selectedRow && [self.selectedRow intValue] < self.remotePeerArray.count) peerId = self.remotePeerArray[[self.selectedRow intValue]];
    [self startFileTransfer:peerId url:[mediaItemCollection.representativeItem valueForProperty:MPMediaItemPropertyAssetURL] type:SKYLINKAssetTypeMusic];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate

- (void)connection:(SKYLINKConnection*)connection didConnectWithMessage:(NSString*)errorMessage success:(BOOL)isSuccess {
    if (isSuccess) {
        NSLog(@"Inside %s", __FUNCTION__);
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Connection failed" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
    });
}

- (void)connection:(SKYLINKConnection*)connection didDisconnectWithMessage:(NSString*)errorMessage {
    [[[UIAlertView alloc] initWithTitle:@"Disconnected" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - SKYLINKConnectionRemotePeerDelegate

- (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId {
    NSLog(@"Peer with id %@ joigned the room.", peerId);
    [self.remotePeerArray addObject:peerId];
    [self.tableView reloadData];
}

- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId {
    NSLog(@"Peer with id %@ left the room with message: %@", peerId, errorMessage);
    [self.remotePeerArray removeObject:peerId];
    [self.tableView reloadData];
}



#pragma mark - SKYLINKConnectionFileTransferDelegate

- (void)connection:(SKYLINKConnection*)connection didReceiveRequest:(NSString*)filename peerId:(NSString*)peerId {
    [[[UIAlertView alloc] initWithTitle:@"Accept file transfer ?"
                                message:[NSString stringWithFormat:@"\nA user wants to send you a file named:\n'%@'", filename]
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"Decline" action:^{
        // Handle "Decline"
        [self.skylinkConnection acceptFileTransfer:NO filename:filename peerId:peerId];
    }]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"Accept" action:^{
        // Handle "Accept" (see UIAlertView-Blocks pod readme if needed)
        [self.skylinkConnection acceptFileTransfer:YES filename:filename peerId:peerId];
    }], nil] show];
    transferInProgressFilename = filename;
}

- (void)connection:(SKYLINKConnection*)connection didReceivePermission:(BOOL)isPermitted filename:(NSString*)filename peerId:(NSString*)peerId {
    if (!isPermitted) {
        [[[UIAlertView alloc] initWithTitle:@"File refused" message:[NSString stringWithFormat:@"The peer user has refused your '%@' file sending request", filename] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    else if (filename && peerId) {
        transferInProgressFilename = filename;
        self.cancelButton.hidden = NO;
    }
}

- (void)connection:(SKYLINKConnection*)connection didDropTransfer:(NSString*)filename reason:(NSString*)message isExplicit:(BOOL)isExplicit peerId:(NSString*)peerId {
    transferInProgressPeerId = nil;
    transferInProgressFilename = nil;
    self.cancelButton.hidden = YES;
    [[[UIAlertView alloc] initWithTitle:@"Transfer dropped" message:[NSString stringWithFormat:@"File transfer dropped.\n%@", (isExplicit)  ? @"Peer user has canceled the file being transferred" : message] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    self.infoLabel.text = @"Transfer dropped";
    self.progressView.hidden = YES;
}

- (void)connection:(SKYLINKConnection*)connection didCompleteTransfer:(NSString*)filename fileData:(NSData*)fileData peerId:(NSString*)peerId {
    
    [[[UIAlertView alloc] initWithTitle:@"Transfer completed" message:[NSString stringWithFormat:@"\nFile transfer success.\n\nPEER\n%@\n\nFILE\n%@", (transferInProgressPeerId) ? transferInProgressPeerId : @"Transfer to all" , transferInProgressFilename] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
    transferInProgressPeerId = nil;
    transferInProgressFilename = nil;
    self.cancelButton.hidden = YES;
    self.infoLabel.text = @"transfer complete";
    self.progressView.hidden = YES;
    
    if (fileData) {
        NSString *fileExtension = [[filename componentsSeparatedByString:@"."] lastObject];
        filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        if ([self isImage:fileExtension] && [UIImage imageWithData:fileData]) {
            UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:fileData], self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)(filename));
        } else {
            NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:filename];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
            
            NSError *wError;
            [fileData writeToFile:filePath options:NSDataWritingAtomic error:&wError];
            if (wError) {
                NSLog(@"%s • Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
            } else {
                if ([self isMovie:fileExtension] && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    [[ALAssetsLibrary new] writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:filePath] completionBlock:^(NSURL *assetURL, NSError *error){
                        if (error) NSLog(@"%s • Error while saving '%@'->%@", __FUNCTION__, filename, error.localizedDescription);
                        else [self removeFileAtPath:filePath];
                    }];
                }
            }
        }
    }
}


#pragma mark - Utils

- (void)startFileTransfer:(NSString*)userId url:(NSURL*)fileURL type:(SKYLINKAssetType)transferType {
    if (transferInProgressPeerId) {
        [[[UIAlertView alloc] initWithTitle:@"Transfer already in progress" message:@"\nMultiple transfers are allowed by the SDK, but for UI clarity in this demo you have to wait the current transfer to be finished before starting a new one." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    else {
        if (userId && fileURL) {
            @try {
                [self.skylinkConnection sendFileTransferRequest:fileURL assetType:transferType peerId:userId];
                transferInProgressPeerId = userId;
                self.cancelButton.hidden = NO;
            }
            @catch (NSException *exception) {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", exception] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        } else if (fileURL) {
            [self.skylinkConnection sendFileTransferRequest:fileURL assetType:transferType]; // No peer ID provided means transfer to every peer in the room
            transferInProgressPeerId = @"";
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"No file URL" message:@"\nError: there is no file URL. Try another merdia." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
}

-(void)showTransferFormForRecipient:(NSString *)peerId {
    NSString *message;
    if (peerId) {
        message = [NSString stringWithFormat:@"\nYou are about to send a tranfer request to user with ID \n%@\nWhat do you want to send ?", peerId];
    }
    else {
        message = @"\nYou are about to send a tranfer request all users\nWhat do you want to send ?";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Send a file."
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil]
                       otherButtonItems:
      [RIButtonItem itemWithLabel:@"Photo / Video (pick from library)" action:^{
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            UIImagePickerController *pickerController = [UIImagePickerController new];
            pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            pickerController.delegate = self;
            pickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, (NSString*) kUTTypeMovie, nil];
            [self presentViewController:pickerController animated:YES completion:nil];
        }
    }]/*,
      [RIButtonItem itemWithLabel:@"Music" action:^{
        MPMediaPickerController *pickerController = [MPMediaPickerController new];
        pickerController.delegate = self;
        [self presentViewController:pickerController animated:YES completion:nil];
    }]*/,
      [RIButtonItem itemWithLabel:@"File (prepared image)" action:^{
        NSString *peerId = nil;
        if (self.selectedRow && [self.selectedRow intValue] < self.remotePeerArray.count) peerId = self.remotePeerArray[[self.selectedRow intValue]];
        NSString *filePath = [[NSBundle mainBundle] pathForResource:((peerId) ? @"sampleImage_transfer" : @"sampleImage_groupTransfer")
                                                             ofType:@"png"
                                                        inDirectory:@"TransferFileSamples"];
        [self startFileTransfer:peerId url:[NSURL URLWithString:filePath] type:SKYLINKAssetTypeFile];
    }],
      nil] show];
    
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"%s • Error while saving '%@'->%@", __FUNCTION__, contextInfo, error.localizedDescription);
        
        NSLog(@"%s • Now trying to save image in the Documents Directory", __FUNCTION__);
        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:(__bridge NSString *)(contextInfo)];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
        
        NSError *wError;
        [UIImagePNGRepresentation(image) writeToFile:filePath options:NSDataWritingAtomic error:&wError];
        if (wError)
            NSLog(@"%s • Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
    } else {
        NSLog(@"%s • Image saved successfully", __FUNCTION__);
    }
}

- (BOOL)removeFileAtPath:(NSString*)filePath {
    BOOL succeed = NO;
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"%s • Error while removing '%@'->%@", __FUNCTION__, filePath, error.localizedDescription);
    } else {
        succeed = YES;
    }
    return succeed;
}

- (BOOL)isImage:(NSString*)extension {
    return [@[@"jpg", @"jpeg", @"jpe", @"jif", @"jfif", @"jfi", @"jp2", @"j2k", @"jpf", @"jpx", @"jpm", @"tiff", @"tif", @"pict", @"pct", @"pic", @"gif", @"png", @"qtif", @"icns", @"bmp", @"bmpf", @"ico", @"cur", @"xbm"] containsObject:[extension lowercaseString]];
}

- (BOOL)isMovie:(NSString*)extension {
    return [@[@"mpg", @"mpeg", @"m1v", @"mpv", @"3gp", @"3gpp", @"sdv", @"3g2", @"3gp2", @"m4v", @"mp4", @"mov", @"qt"] containsObject:[extension lowercaseString]];
}


#pragma mark - IBActions

- (IBAction)sendToAllTap:(UIButton *)sender {
    self.selectedRow = nil;
    if (self.remotePeerArray.count > 0) {
        [self showTransferFormForRecipient:nil];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"No peer connected" message:@"Wait for someone to connect before sending files." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (IBAction)cancelTap:(UIButton *)sender {
    if (transferInProgressPeerId && transferInProgressPeerId.length > 0 && transferInProgressFilename) {
        [self.skylinkConnection cancelFileTransfer:transferInProgressFilename peerId:transferInProgressPeerId];
        transferInProgressPeerId = nil;
        transferInProgressFilename = nil;
        self.infoLabel.text = @"Transfer canceled";
        self.progressView.hidden = YES;
    }
    self.cancelButton.hidden = YES;
}

@end


