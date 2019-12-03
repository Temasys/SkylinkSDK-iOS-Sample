//
//  FileTransferViewController.m
//  Skylink_Examples
//
//  Created by Temasys on 18/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "FileTransferViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "Constant.h"

//#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_FILETRANSFER"]


@interface FileTransferViewController ()<MPMediaPickerControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SKYLINKConnectionFileTransferDelegate>
// IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *peersTableView;
@property (weak, nonatomic) IBOutlet UITableView *fileTransferTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


// Other properties
@property (strong, nonatomic) NSMutableArray *remotePeerArray; // array holding the ids (strings) of the peers connected to the room
@property (strong, nonatomic) NSMutableArray *transfersArray; // array of dictionnaries holding infos about started (and finished) file transfers

@property (strong, nonatomic) AVAudioPlayer *musicPlayer;
@property (assign, nonatomic) NSNumber *selectedRow;

@property (strong, nonatomic) UIImagePickerController *pickerController;
@end



@implementation FileTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"File Transfer";
    self.remotePeerArray = [[NSMutableArray alloc] init];
    self.transfersArray = [[NSMutableArray alloc] init];
    
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    [config setAudioVideoSendConfig:AudioVideoConfig_NO_AUDIO_NO_VIDEO];
    [config setAudioVideoReceiveConfig:AudioVideoConfig_NO_AUDIO_NO_VIDEO];
    config.hasFileTransfer = YES;
    [config setTimeout:30 skylinkAction:SkylinkAction_FILE_SEND_REQUEST];
    // Creating SKYLINKConnection
    _skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config callback:nil];
    _skylinkConnection.lifeCycleDelegate = self;
    _skylinkConnection.fileTransferDelegate = self;
    _skylinkConnection.remotePeerDelegate = self;
    // Connecting to a room
    [_skylinkConnection connectToRoomWithAppKey:APP_KEY secret:APP_SECRET roomName:ROOM_FILE_TRANSFER userData:USER_NAME callback:nil];
}


// Table View
#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    if ([tableView isEqual:self.peersTableView]) {
        if (section == 0) title = (self.remotePeerArray.count > 0) ? @"Or select a connected peer recipient:" : @"No peer connected yet";
    } else if ([tableView isEqual:self.fileTransferTableView]) title = [NSString stringWithFormat:@"File transfers (%lu)", (unsigned long)self.transfersArray.count];
    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount;
    if ([tableView isEqual:self.peersTableView]) rowCount = self.remotePeerArray.count;
    else rowCount = self.transfersArray.count;
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ([tableView isEqual:self.peersTableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"];
        cell.textLabel.text = [NSString stringWithFormat:@"Peer %ld, ID: %@", (long)indexPath.row + 1, [self.remotePeerArray objectAtIndex:indexPath.row]];
    } else if ([tableView isEqual:self.fileTransferTableView]) {
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
    } else if ([tableView isEqual:self.fileTransferTableView]) {
        NSDictionary *transferInfos = self.transfersArray[indexPath.row];
        if ([transferInfos[@"state"] isEqualToString:@"In progress"]) { // then ask confirmation for transfer drop
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Cancel file transfer ?" message:[NSString stringWithFormat:@"\nCancel file transfer for filename:\n'%@'\npeer ID:\n%@", transferInfos[@"filename"], transferInfos[@"peerId"]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Drop transfer" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // cancel transfer if not finished
                if ([self.transfersArray[indexPath.row][@"state"] isEqualToString:@"In progress"]) { // because transfer could be completed after alert showed up
                    [_skylinkConnection cancelFileTransferWithRemotePeerId:transferInfos[@"peerId"] forSending:NO callback:^(NSError * _Nullable error) {
                    }];
                [self updateFileTranferInfosForFilename:transferInfos[@"filename"] peerId:transferInfos[@"peerId"] withState:@"Cancelled" progress:[transferInfos[@"progress"] floatValue] isOutgoing:[transferInfos[@"isOutgoing"] boolValue]];
                } else [UIAlertController showAlertWithAutoDisappearTitle:@"Can not cancel" message:@"Transfer already completed" duration:3 onViewController:self];
            }];
            UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue transfer" style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:cancelAction];
            [alertController addAction:continueAction];
            [self presentViewController:alertController animated:YES completion:^{
            }];
        } else [UIAlertController showAlertWithAutoDisappearTitle:@"Transfer details" message:transferInfos.description duration:3 onViewController:self];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *peerId = nil;
    if (self.selectedRow && [self.selectedRow intValue] < self.remotePeerArray.count) peerId = self.remotePeerArray[[self.selectedRow intValue]];
    [self startFileTransfer:peerId url:info[UIImagePickerControllerReferenceURL] type:SKYLINKAssetTypePhoto];
    [picker dismissViewControllerAnimated:YES completion:nil];
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
- (void)connectionDidConnectToRoomSuccessful:(SKYLINKConnection *)connection
{
    MyLog(@"Connection success :D");
    [self.activityIndicator stopAnimating];
}

- (void)connection:(SKYLINKConnection *)connection didConnectToRoomFailed:(NSString *)errorMessage
{
    [UIAlertController showAlertWithAutoDisappearTitle:@"Connection failed" message:errorMessage duration:3 onViewController:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)connection:(SKYLINKConnection *)connection didDisconnectFromRoomWithSkylinkEvent:(NSDictionary *)skylinkEvent contextDescription:(NSString *)contextDescription
{
//    [UIAlertController showAlertWithAutoDisappearTitle:@"Disconnected" message:contextDescription duration:3 onViewController:self];
//    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark SKYLINKConnectionRemotePeerDelegate
- (void)connection:(SKYLINKConnection *)connection didConnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel
{
    MyLog(@"Peer with id %@ joigned the room, properties: %@", remotePeerId, userInfo);
    [self.remotePeerArray addObject:remotePeerId];
    [self.peersTableView reloadData];
}

- (void)connection:(SKYLINKConnection *)connection didDisconnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel
{
    MyLog(@"Peer with id %@ left the room with message: %@", remotePeerId, userInfo);
    [self.remotePeerArray removeObject:remotePeerId];
    [self.peersTableView reloadData];
}

- (void)connection:(SKYLINKConnection *)connection didReceiveRemotePeerUserData:(id)userData remotePeerId:(NSString *)remotePeerId
{
    MyLog(@"Peer with id %@ left the room with message: %@", remotePeerId, userData);
    [self.remotePeerArray removeObject:remotePeerId];
    [self.peersTableView reloadData];
}

- (void)connection:(SKYLINKConnection *)connection didErrorForRemotePeerConnection:(NSError *)error remotePeerId:(NSString *)remotePeerId
{
    MyLog(@"Peer with id %@ left the room with message: %@", remotePeerId, error);
    [self.remotePeerArray removeObject:remotePeerId];
    [self.peersTableView reloadData];
}


#pragma mark SKYLINKConnectionFileTransferDelegate
- (void)connection:(SKYLINKConnection *)connection didReceiveFileTransferRequest:(NSString *)fileName isPublic:(BOOL)isPublic remotePeerId:(NSString *)remotePeerId
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Accept file transfer ?" message:[NSString stringWithFormat:@"\nA user wants to send you a file named:\n'%@'", fileName] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *declineAction = [UIAlertAction actionWithTitle:@"Decline" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [_skylinkConnection rejectFileTransferFromRemotePeerId:remotePeerId callback:^(NSError * _Nullable error) {
            if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
        }];
    }];
    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"Accept" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [_skylinkConnection acceptFileTransferWithFileName:fileName fromRemotePeerId:remotePeerId callback:^(NSError * _Nullable error) {
            if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
        }];
    }];
    [alertController addAction:declineAction];
    [alertController addAction:acceptAction];
    [self presentViewController:alertController animated:YES completion:^{
    }];
}

- (void)connection:(SKYLINKConnection *)connection didReceiveFileTransferResponse:(BOOL)wasAccepted fileName:(NSString *)fileName remotePeerId:(NSString *)remotePeerId
{
    if (!wasAccepted) [UIAlertController showAlertWithAutoDisappearTitle:@"File refused" message:[NSString stringWithFormat:@"The peer user has refused your '%@' file sending request", fileName] duration:3 onViewController:self];
}

- (void)connection:(SKYLINKConnection *)connection didUpdateFileTransferSendingProgress:(CGFloat)percentage fileName:(NSString *)fileName remotePeerId:(NSString *)remotePeerId
{
    [self updateFileTranferInfosForFilename:fileName peerId:((remotePeerId) ? remotePeerId : @"all") withState:@"In progress" progress:percentage isOutgoing:YES];
}

- (void)connection:(SKYLINKConnection *)connection didUpdateFileTransferReceivingProgress:(CGFloat)percentage fileName:(NSString *)fileName remotePeerId:(NSString *)remotePeerId
{
    [self updateFileTranferInfosForFilename:fileName peerId:((remotePeerId) ? remotePeerId : @"all") withState:@"In progress" progress:percentage isOutgoing:NO];
}

- (void)connection:(SKYLINKConnection *)connection didDropFileTransfer:(NSString *)fileName message:(NSString *)message isExplicit:(BOOL)isExplicit remotePeerId:(NSString *)remotePeerId
{
    [self updateFileTranferInfosForFilename:fileName peerId:((remotePeerId) ? remotePeerId : @"all") withState:((message.length) ? message : @"Dropped by sender") progress:0 isOutgoing:isExplicit];
}

- (void)connection:(SKYLINKConnection *)connection didCompleteFileTransferReceiving:(NSString *)fileName fileData:(NSData *)fileData fileSavePath:(NSString *)fileSavePath remotePeerId:(NSString *)remotePeerId
{
    [self updateFileTranferInfosForFilename:fileName peerId:((remotePeerId) ? remotePeerId : @"all") withState:@"Completed ✓" progress:1 isOutgoing:NO];
    if (fileData) {
        NSString *fileExtension = [[fileName componentsSeparatedByString:@"."] lastObject];
        fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        if ([self isImage:fileExtension] && [UIImage imageWithData:fileData]) {
            UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:fileData], self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)(fileName));
        } else if ([fileExtension isEqualToString:@"mp3"] || [fileExtension isEqualToString:@"m4a"]) {
            NSError *pError;
            self.musicPlayer = [fileExtension isEqualToString:@"mp3"] ? [[AVAudioPlayer alloc] initWithData:fileData fileTypeHint:AVFileTypeMPEGLayer3 error:&pError] : [[AVAudioPlayer alloc] initWithData:fileData error:&pError];
            if (!pError) [self.musicPlayer play];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Music transfer completed" message:[NSString stringWithFormat:@"File transfer success.\nPEER: %@\n\nPlaying the received music file:\n'%@'", remotePeerId, fileName] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Stop playing" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self.musicPlayer stop];
                self.musicPlayer = nil;
            }];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:^{
            }];
        } else {
            NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
            NSError *wError;
            [fileData writeToFile:filePath options:NSDataWritingAtomic error:&wError];
            if (wError) {
                MyLog(@"%s • Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
            } else {
                MyLog(@"File saved at %@", filePath);
                if ([self isMovie:fileExtension] && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:filePath]];
                        NSParameterAssert(createAssetRequest);
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        if (error) MyLog(@"%s • Error while saving '%@'->%@", __FUNCTION__, fileName, error.localizedDescription);
                        else [self removeFileAtPath:filePath];
                    }];
                }
            }
        }
    }
}

#pragma mark - other methods

- (void)updateFileTranferInfosForFilename:(NSString *)filename peerId:(NSString *)peerId withState:(NSString *)state progress:(CGFloat)percentage isOutgoing:(BOOL)isOutgoing {
    NSInteger indexOfTransfer = [self.transfersArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ([((NSDictionary *)obj)[@"filename"] isEqualToString:filename] && [((NSDictionary *)obj)[@"peerId"] isEqualToString:peerId]);
    }];
    if (indexOfTransfer == NSNotFound) { // new transfer
        [self.transfersArray insertObject:@{@"filename" : (filename) ? filename : @"none", @"peerId" : (peerId) ? peerId : @"No peer ID", @"isOutgoing" : @(isOutgoing), @"percentage" : @(percentage), @"state" : (state) ? state : @"Undefined"} atIndex:0];
    } else { // updated transfer
        NSMutableDictionary *transferInfos = [NSMutableDictionary dictionaryWithDictionary:self.transfersArray[indexOfTransfer]];
        if (filename) [transferInfos setObject:filename forKey:@"filename"];
        if (peerId) [transferInfos setObject:peerId forKey:@"peerId"];
        if (isOutgoing) [transferInfos setObject:@(isOutgoing) forKey:@"isOutgoing"];
        if (percentage) [transferInfos setObject:@(percentage) forKey:@"percentage"];
        if (state) [transferInfos setObject:state forKey:@"state"];
        [self.transfersArray replaceObjectAtIndex:indexOfTransfer withObject:transferInfos];
    }
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.fileTransferTableView reloadData];
    });
}

- (void)startFileTransfer:(NSString *)userId url:(NSURL *)fileURL type:(SKYLINKAssetType)transferType {
    
    if (userId && fileURL) {
        @try {
            [_skylinkConnection sendFileTransferWithFileURL:fileURL assetType:transferType fileName:nil remotePeerId:userId callback:^(NSError * _Nullable error) {
                if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
            }];
        } @catch (NSException *exception) {
            [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:[NSString stringWithFormat:@"%@", exception] duration:3 onViewController:self];
        }
    } else if (fileURL) {
        [_skylinkConnection sendFileTransferWithFileURL:fileURL assetType:transferType fileName:nil remotePeerId:nil callback:^(NSError * _Nullable error) {
            
        }];
    } else {
        [UIAlertController showAlertWithAutoDisappearTitle:@"No file URL" message:@"\nError: there is no file URL. Try another media." duration:3 onViewController:self];
    }
}

- (void)showTransferFormForRecipient:(NSString *)peerId {
    NSString *message;
    if (peerId) message = [NSString stringWithFormat:@"\nYou are about to send a tranfer request to user with ID \n%@\nWhat do you want to send ?", peerId];
    else message = @"\nYou are about to send a tranfer request all users\nWhat do you want to send ?";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Send a file." message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *acceptPhotoAction = [UIAlertAction actionWithTitle:@"Photo / Video (pick from library)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            self.pickerController = [UIImagePickerController new];
            self.pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.pickerController.delegate = self;
            self.pickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, (NSString*) kUTTypeMovie, nil];
            [self presentViewController:self.pickerController animated:YES completion:nil];
        }
    }];
    UIAlertAction *acceptMusicAction = [UIAlertAction actionWithTitle:@"Music (pick from library)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        MPMediaPickerController *pickerController = [MPMediaPickerController new];
        pickerController.delegate = self;
        [self presentViewController:pickerController animated:YES completion:nil];
    }];
    UIAlertAction *acceptFileAction = [UIAlertAction actionWithTitle:@"File (prepared image)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *peerId = nil;
        if (self.selectedRow && [self.selectedRow intValue] < self.remotePeerArray.count) peerId = self.remotePeerArray[[self.selectedRow intValue]];
        NSString *filePath = [[NSBundle mainBundle] pathForResource:((peerId) ? @"sampleImage_transfer" : @"sampleImage_groupTransfer") ofType:@"png" inDirectory:@"TransferFileSamples"];
        [self startFileTransfer:peerId url:[NSURL URLWithString:filePath] type:SKYLINKAssetTypeFile];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:acceptPhotoAction];
    [alertController addAction:acceptMusicAction];
    [alertController addAction:acceptFileAction];
    [self presentViewController:alertController animated:YES completion:^{
    }];
}

#pragma mark - IBActions

- (IBAction)sendToAllTap:(UIButton *)sender {
    self.selectedRow = nil;
    if (self.remotePeerArray.count > 0)  [self showTransferFormForRecipient:nil];
    else [UIAlertController showAlertWithAutoDisappearTitle:@"No peer connected" message:@"Wait for someone to connect before sending files." duration:3 onViewController:self];
}


#pragma mark - Utils

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        MyLog(@"%s • Error while saving '%@'->%@", __FUNCTION__, contextInfo, error.localizedDescription);
        MyLog(@"%s • Now trying to save image in the Documents Directory", __FUNCTION__);
        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:(__bridge NSString *)(contextInfo)];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
        NSError *wError;
        [UIImagePNGRepresentation(image) writeToFile:filePath options:NSDataWritingAtomic error:&wError];
        if (wError) MyLog(@"%s • Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
    } else {
        MyLog(@"%s • Image saved successfully", __FUNCTION__);
    }
}

- (BOOL)removeFileAtPath:(NSString*)filePath {
    BOOL succeed = NO;
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) MyLog(@"%s • Error while removing '%@'->%@", __FUNCTION__, filePath, error.localizedDescription);
    else succeed = YES;
    return succeed;
}

- (BOOL)isImage:(NSString*)extension {
    return [@[@"jpg", @"jpeg", @"jpe", @"jif", @"jfif", @"jfi", @"jp2", @"j2k", @"jpf", @"jpx", @"jpm", @"tiff", @"tif", @"pict", @"pct", @"pic", @"gif", @"png", @"qtif", @"icns", @"bmp", @"bmpf", @"ico", @"cur", @"xbm"] containsObject:[extension lowercaseString]];
}
- (BOOL)isMovie:(NSString*)extension {
    return [@[@"mpg", @"mpeg", @"m1v", @"mpv", @"3gp", @"3gpp", @"sdv", @"3g2", @"3gp2", @"m4v", @"mp4", @"mov", @"qt"] containsObject:[extension lowercaseString]];
}


@end


