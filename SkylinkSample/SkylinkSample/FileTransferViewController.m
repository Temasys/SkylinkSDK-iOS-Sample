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
#import <AVFoundation/AVFoundation.h>


#define ROOM_NAME  @"FILE-TRANSFER-ROOM"


@interface FileTransferViewController ()
// IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *peersTableView;
@property (weak, nonatomic) IBOutlet UITableView *fileTransferTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


// Other properties
@property (strong, nonatomic) SKYLINKConnection *skylinkConnection;
@property (strong, nonatomic) NSMutableArray *remotePeerArray; // array holding the ids (strings) of the peers connected to the room
@property (strong, nonatomic) NSMutableArray *transfersArray; // array of dictionnaries holding infos about started (and finished) file transfers

@property (strong, nonatomic) AVAudioPlayer *musicPlayer;
@property (assign, nonatomic) NSNumber *selectedRow;
@end



@implementation FileTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"File transfer";
    self.remotePeerArray = [[NSMutableArray alloc] init];
    self.transfersArray = [[NSMutableArray alloc] init];
    
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
#ifdef DEBUG
    [SKYLINKConnection setVerbose:TRUE];
#endif
    // Connecting to a room
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

// Table View
#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    if ([tableView isEqual:self.peersTableView]) {
        if (section == 0) {
            title = (self.remotePeerArray.count > 0) ? @"Or select a connected peer recipient:" : @"No peer connected yet";
        }
    }
    else if ([tableView isEqual:self.fileTransferTableView]) {
        title = [NSString stringWithFormat:@"File transfers (%lu)", (unsigned long)self.transfersArray.count];
    }
    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount;
    if ([tableView isEqual:self.peersTableView]) {
        rowCount = self.remotePeerArray.count;
    }
    else if ([tableView isEqual:self.fileTransferTableView]) {
        rowCount = self.transfersArray.count;
    }
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ([tableView isEqual:self.peersTableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"];
        cell.textLabel.text = [NSString stringWithFormat:@"Peer %ld, ID: %@", (long)indexPath.row + 1, [self.remotePeerArray objectAtIndex:indexPath.row]];
    }
    else if ([tableView isEqual:self.fileTransferTableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"fileTransferCell"];
        NSDictionary *trInfos = [self.transfersArray objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %.0f%% • %@", [trInfos[@"isOutgoing"] boolValue] ? @"⬆️" : @"⬇️", ([trInfos[@"percentage"] floatValue] * 100), trInfos[@"state"]];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"File: %@ • Peer: %@", trInfos[@"filename"], trInfos[@"peerId"]];
    }
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([tableView isEqual:self.peersTableView] && [view isKindOfClass:[UITableViewHeaderFooterView class]]) ((UITableViewHeaderFooterView *)view).textLabel.textColor = [UIColor lightGrayColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([tableView isEqual:self.peersTableView]) {
        self.selectedRow = [NSNumber numberWithInteger:indexPath.row];
        [self showTransferFormForRecipient:self.remotePeerArray[indexPath.row]];
    }
    else if ([tableView isEqual:self.fileTransferTableView]) {
        
        NSDictionary *transferInfos = self.transfersArray[indexPath.row];
        
        if ([transferInfos[@"state"] isEqualToString:@"In progress"]) { // then ask confirmation for transfer drop
            
            [[[UIAlertView alloc] initWithTitle:@"Cancel file transfer ?"
                                        message:[NSString stringWithFormat:@"\nCancel file transfer for filename:\n'%@'\npeer ID:\n%@", transferInfos[@"filename"], transferInfos[@"peerId"]]
                               cancelButtonItem:[RIButtonItem itemWithLabel:@"Drop transfer" action:^{
                // cancel transfer if not finished
                if ([self.transfersArray[indexPath.row][@"state"] isEqualToString:@"In progress"]) { // because transfer could be completed after alert showed up
                [self.skylinkConnection cancelFileTransfer:transferInfos[@"filename"] peerId:transferInfos[@"peerId"]];
                [self updateFileTranferInfosForFilename:transferInfos[@"filename"] peerId:transferInfos[@"peerId"] withState:@"Cancelled" progress:transferInfos[@"progress"] isOutgoing:transferInfos[@"isOutgoing"]];
                }
                else {
                    [[[UIAlertView alloc] initWithTitle:@"Can not cancel" message:@"Transfer already completed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }]
                              otherButtonItems:[RIButtonItem itemWithLabel:@"Continue transfer" action:nil], nil] show];
        }
        else { // show infos
            [[[UIAlertView alloc] initWithTitle:@"Transfer details" message:transferInfos.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
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


// SKYLINK Delegate methods implementations
#pragma mark - SKYLINKConnectionLifeCycleDelegate

- (void)connection:(SKYLINKConnection*)connection didConnectWithMessage:(NSString*)errorMessage success:(BOOL)isSuccess {
    [self.activityIndicator stopAnimating];
    if (isSuccess) {
        NSLog(@"Connection success :D");
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Connection failed" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)connection:(SKYLINKConnection*)connection didDisconnectWithMessage:(NSString*)errorMessage {
    [[[UIAlertView alloc] initWithTitle:@"Disconnected" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark SKYLINKConnectionRemotePeerDelegate

- (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId {
    NSLog(@"Peer with id %@ joigned the room, properties: %@", peerId, pmProperties.description);
    [self.remotePeerArray addObject:peerId];
    [self.peersTableView reloadData];
}

- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId {
    NSLog(@"Peer with id %@ left the room with message: %@", peerId, errorMessage);
    [self.remotePeerArray removeObject:peerId];
    [self.peersTableView reloadData];
}



#pragma mark SKYLINKConnectionFileTransferDelegate

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
}

- (void)connection:(SKYLINKConnection*)connection didReceivePermission:(BOOL)isPermitted filename:(NSString*)filename peerId:(NSString*)peerId {
    if (!isPermitted) {
        [[[UIAlertView alloc] initWithTitle:@"File refused" message:[NSString stringWithFormat:@"The peer user has refused your '%@' file sending request", filename] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)connection:(SKYLINKConnection*)connection didUpdateProgress:(CGFloat)percentage isOutgoing:(BOOL)isOutgoing filename:(NSString*)filename peerId:(NSString*)peerId {
    
    [self updateFileTranferInfosForFilename:filename peerId:((peerId) ? peerId : @"all") withState:@"In progress" progress:[NSNumber numberWithFloat:percentage] isOutgoing:[NSNumber numberWithBool:isOutgoing]];
}


- (void)connection:(SKYLINKConnection*)connection didDropTransfer:(NSString*)filename reason:(NSString*)message isExplicit:(BOOL)isExplicit peerId:(NSString*)peerId {
    
    [self updateFileTranferInfosForFilename:filename peerId:((peerId) ? peerId : @"all") withState:((message.length) ? message : @"Dropped by sender") progress:nil isOutgoing:nil];
}

- (void)connection:(SKYLINKConnection*)connection didCompleteTransfer:(NSString*)filename fileData:(NSData*)fileData peerId:(NSString*)peerId {
    
    [self updateFileTranferInfosForFilename:filename peerId:((peerId) ? peerId : @"all") withState:@"Completed ✓" progress:@1 isOutgoing:nil];
    
    
    if (fileData) {
        NSString *fileExtension = [[filename componentsSeparatedByString:@"."] lastObject];
        filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        if ([self isImage:fileExtension] && [UIImage imageWithData:fileData]) {
            UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:fileData], self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)(filename));
        }
        else if ([fileExtension isEqualToString:@"mp3"] || [fileExtension isEqualToString:@"m4a"]) {
            NSError *pError;
            self.musicPlayer = [fileExtension isEqualToString:@"mp3"] ? [[AVAudioPlayer alloc] initWithData:fileData fileTypeHint:AVFileTypeMPEGLayer3 error:&pError] : [[AVAudioPlayer alloc] initWithData:fileData error:&pError];
            if (!pError) [self.musicPlayer play];
            /*alertToShow = */[[[UIAlertView alloc] initWithTitle:@"Music transfer completed"
                                                     message:[NSString stringWithFormat:@"File transfer success.\nPEER: %@\n\nPlaying the received music file:\n'%@'", peerId, filename]
                                            cancelButtonItem:[RIButtonItem itemWithLabel:@"Stop playing" action:^{
                                                                [self.musicPlayer stop];
                                                                self.musicPlayer = nil;
                                                            }]
                                            otherButtonItems:nil] show];
        }
        else {
            NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:filename];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
            
            NSError *wError;
            [fileData writeToFile:filePath options:NSDataWritingAtomic error:&wError];
            if (wError) {
                NSLog(@"%s • Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
            } else {
                NSLog(@"File saved at %@", filePath);
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


#pragma mark - other methods

-(void)updateFileTranferInfosForFilename:(NSString *)filename peerId:(NSString *)peerId withState:(NSString *)state progress:(NSNumber *)percentage isOutgoing:(NSNumber *)isOutgoing {
    NSInteger indexOfTransfer = [self.transfersArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ([((NSDictionary *)obj)[@"filename"] isEqualToString:filename] && [((NSDictionary *)obj)[@"peerId"] isEqualToString:peerId]);
    }];
    if (indexOfTransfer == NSNotFound) { // new transfer
        [self.transfersArray insertObject:@{@"filename" : (filename) ? filename : @"none",
                                            @"peerId" : (peerId) ? peerId : @"No peer ID",
                                            @"isOutgoing" : (isOutgoing) ? isOutgoing : @NO,
                                            @"percentage" : (percentage) ? percentage : @(-0),
                                            @"state" : (state) ? state : @"Undefined"
                                            }
                                  atIndex:0];
    }
    else { // updated transfer
        NSMutableDictionary *transferInfos = [NSMutableDictionary dictionaryWithDictionary:self.transfersArray[indexOfTransfer]];
        if (filename) [transferInfos setObject:filename forKey:@"filename"];
        if (peerId) [transferInfos setObject:peerId forKey:@"peerId"];
        if (isOutgoing) [transferInfos setObject:isOutgoing forKey:@"isOutgoing"];
        if (percentage) [transferInfos setObject:percentage forKey:@"percentage"];
        if (state) [transferInfos setObject:state forKey:@"state"];
        [self.transfersArray replaceObjectAtIndex:indexOfTransfer withObject:transferInfos];
    }
    
    [self.fileTransferTableView reloadData];
}

- (void)startFileTransfer:(NSString*)userId url:(NSURL*)fileURL type:(SKYLINKAssetType)transferType {
    
    if (userId && fileURL) {
        @try {
            [self.skylinkConnection sendFileTransferRequest:fileURL assetType:transferType peerId:userId];
        }
        @catch (NSException *exception) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", exception] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    } else if (fileURL) {
        [self.skylinkConnection sendFileTransferRequest:fileURL assetType:transferType]; // No peer ID provided means transfer to every peer in the room
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"No file URL" message:@"\nError: there is no file URL. Try another media." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
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
    }],
      [RIButtonItem itemWithLabel:@"Music (pick from library)" action:^{
        MPMediaPickerController *pickerController = [MPMediaPickerController new];
        pickerController.delegate = self;
        [self presentViewController:pickerController animated:YES completion:nil];
    }],
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


#pragma mark - Utils

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


@end


