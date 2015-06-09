//
//  TEMPresenceTableViewController.m
//  TEM
//
//  Created by macbookpro on 02/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <SKYLINK/SKYLINK.h>

#import "TEMPresenceTableViewController.h"

#import "JSQDemoViewController.h"

#import "SampleAppSwift-Swift.h"

@interface PresenceTableEntry : NSObject

@property (nonatomic, copy) NSString *nick;
@property (nonatomic, copy) NSString *peerId;

@property (nonatomic, strong) UIColor *color;

@end

@implementation PresenceTableEntry

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.color = [UIColor blackColor];
    }
    return self;
}

@end

@interface TEMPresenceTableViewController () {
    NSInteger selectedRow;
    NSMutableArray *presenceArray;
    NSMutableDictionary *chatDictionary;
    UIPopoverController *popoverController;
}

@property (nonatomic, weak) JSQDemoViewController *demoViewController;

@end

@implementation TEMPresenceTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        PresenceTableEntry *entry = [PresenceTableEntry new];
        entry.nick = @"All Participants";
        presenceArray = [NSMutableArray arrayWithObject:entry];
        chatDictionary = [NSMutableDictionary dictionaryWithObject:[NSMutableArray array] forKey:entry.nick];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = @"Participants";
    
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [titleButton setTitle:self.title forState:UIControlStateNormal];
    [titleButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [titleButton addTarget:self action:@selector(titleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = titleButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return presenceArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"PresenceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    // Configure the cell...
    PresenceTableEntry *entry = [presenceArray objectAtIndex:indexPath.row];
    cell.textLabel.text = entry.nick;
    cell.textLabel.textColor = entry.color;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    // <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    // [self.navigationController pushViewController:detailViewController animated:YES];
    
    selectedRow = indexPath.row;
    // Open chat if either of the fileTransfer or dataChannel is not enabled
    BOOL openChat = !(((AppDelegate*)[UIApplication sharedApplication].delegate).appConfig.fileTransfer && ((AppDelegate*)[UIApplication sharedApplication].delegate).appConfig.dataChannel);
    if (selectedRow == 0 || openChat) {
        [self openChat];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open Chat", @"Send Photo", @"Send Music", @"Send File", nil];
        [sheet showInView:self.view];
    }
}

#pragma mark - MPMediaPickerControllerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *peerId = nil;
    if (selectedRow > 0)
        peerId = ((PresenceTableEntry*)[presenceArray objectAtIndex:selectedRow]).peerId;
    [((AppDelegate*)[UIApplication sharedApplication].delegate).roomViewController startFileTransfer:peerId fileURL:[mediaItemCollection.representativeItem valueForProperty:MPMediaItemPropertyAssetURL] transferType:SKYLINKAssetTypeMusic];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self openChat];
            break;
        case 1:
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *pickerController = [UIImagePickerController new];
                pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                pickerController.delegate = self;
                pickerController.mediaTypes =
                [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, (NSString*) kUTTypeMovie, nil];
                if (((AppDelegate*)[UIApplication sharedApplication].delegate).isPad) {
                    popoverController = [[UIPopoverController alloc] initWithContentViewController:pickerController];
                    [popoverController presentPopoverFromRect:CGRectZero inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
                } else {
                    [(AppDelegate*)[UIApplication sharedApplication].delegate presentOverRoomViewController:pickerController];
                }
            }
            break;
        case 2:
        {
            MPMediaPickerController *pickerController = [MPMediaPickerController new];
            pickerController.delegate = self;
            [(AppDelegate*)[UIApplication sharedApplication].delegate presentOverRoomViewController:pickerController];
        }
            break;
        case 3:
        {
            TEMFilePickerController *pickerController = [[TEMFilePickerController alloc] initWithNibName:nil bundle:nil];
            pickerController.delegate = self;
            [(AppDelegate*)[UIApplication sharedApplication].delegate presentOverRoomViewController:pickerController];
        }
            break;
        default:
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (popoverController) {
        [popoverController dismissPopoverAnimated:YES];
        popoverController = nil;
    } else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    NSString *peerId = nil;
    if (selectedRow > 0)
        peerId = ((PresenceTableEntry*)[presenceArray objectAtIndex:selectedRow]).peerId;
    [((AppDelegate*)[UIApplication sharedApplication].delegate).roomViewController startFileTransfer:peerId fileURL:info[UIImagePickerControllerReferenceURL] transferType:SKYLINKAssetTypePhoto];
}

#pragma mark - TEMFilePickerControllerDelegate

- (void)filePicker:(TEMFilePickerController*)filePicker didPickFile:(NSURL*)fileURL
{
    [filePicker dismissViewControllerAnimated:YES completion:nil];
    NSString *peerId = nil;
    if (selectedRow > 0)
        peerId = ((PresenceTableEntry*)[presenceArray objectAtIndex:selectedRow]).peerId;
    [((AppDelegate*)[UIApplication sharedApplication].delegate).roomViewController startFileTransfer:peerId fileURL:fileURL transferType:SKYLINKAssetTypeFile];
}

- (void)filePickerDidCancel:(TEMFilePickerController*)filePicker
{
    [filePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - public methods

- (void)addChatMessage:(NSString*)message nick:(NSString*)nick peerId:(NSString*)peerId isPublic:(BOOL)isPublic
{
    if (self.demoViewController) {
        if (isPublic) {
            if (!self.demoViewController.peerId) {
                [self.demoViewController receiveMessage:message nick:nick];
            } else {
                PresenceTableEntry *entry = [presenceArray objectAtIndex:0];
                entry.color = [UIColor blueColor];
                NSString *dataKey = entry.nick;
                NSMutableArray *array = [chatDictionary objectForKey:dataKey];
                [array addObject:@{@"user": nick, @"text": message}];
                [self.tableView reloadData];
            }
        } else {
            if ([peerId caseInsensitiveCompare:self.demoViewController.peerId] == NSOrderedSame) {
                [self.demoViewController receiveMessage:message nick:nick];
            } else {
                for (PresenceTableEntry *entry in presenceArray)
                    if ([peerId caseInsensitiveCompare:entry.peerId] == NSOrderedSame) {
                        entry.color = [UIColor blueColor];
                        break;
                    }
                NSMutableArray *array = [chatDictionary objectForKey:peerId];
                [array addObject:@{@"user": nick, @"text": message}];
                [self.tableView reloadData];
            }
        }
    } else {
        NSString *dataKey = peerId;
        if (isPublic) {
            ((PresenceTableEntry*)[presenceArray objectAtIndex:0]).color = [UIColor blueColor];
            dataKey = ((PresenceTableEntry*)[presenceArray objectAtIndex:0]).nick;
        } else {
            for (PresenceTableEntry *entry in presenceArray)
                if ([dataKey caseInsensitiveCompare:entry.peerId] == NSOrderedSame) {
                    entry.color = [UIColor blueColor];
                    break;
                }
        }
        NSMutableArray *array = [chatDictionary objectForKey:dataKey];
        [array addObject:@{@"user": nick, @"text": message}];
        [self.tableView reloadData];
    }
}

- (void)addParticipant:(NSString*)nick peerId:(NSString*)peerId
{
    PresenceTableEntry *entry = [PresenceTableEntry new];
    entry.peerId = peerId;
    entry.nick = nick;
    [presenceArray addObject:entry];
    [chatDictionary setObject:[NSMutableArray array] forKey:peerId];
    [self.tableView reloadData];
}

- (void)deleteParticipant:(NSString*)peerId
{
    for (PresenceTableEntry *entry in presenceArray)
        if ([peerId caseInsensitiveCompare:entry.peerId] == NSOrderedSame) {
            [chatDictionary removeObjectForKey:entry.peerId];
            [presenceArray removeObject:entry];
            break;
        }
    [self.tableView reloadData];
}

- (void)highlightPanelButton
{
    if (self.demoViewController)
        [self.demoViewController highlightPanelButton];
    else
        [(UIButton*)self.navigationItem.titleView setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
}

- (NSString*)updateParticipant:(NSString*)nick peerId:(NSString*)peerId
{
    NSString *oldNick;
    for (PresenceTableEntry *entry in presenceArray)
        if ([peerId caseInsensitiveCompare:entry.peerId] == NSOrderedSame) {
            oldNick = entry.nick;
            entry.nick = nick;
            break;
        }
    [self.tableView reloadData];
    return oldNick;
}

#pragma mark - IBAction

- (IBAction)titleButtonTapped:(id)sender {
    UIButton *button = (UIButton*)sender;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MINIMIZE_PRESENCE" object:nil];
}

#pragma mark - private methods

- (void)openChat
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    UIColor *newColor = [UIColor blackColor];
    [self.tableView cellForRowAtIndexPath:indexPath].textLabel.textColor = newColor;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    PresenceTableEntry *entry = [presenceArray objectAtIndex:indexPath.row];
    entry.color = newColor;
    JSQDemoViewController *vc = [JSQDemoViewController messagesViewController];
    vc.chatNick = entry.nick;
    // Invoking viewDidLoad
    vc.view;
    if (entry.peerId) {
        vc.peerId = entry.peerId;
        [vc setupModel:[chatDictionary objectForKey:entry.peerId]];
    } else {
        [vc setupModel:[chatDictionary objectForKey:entry.nick]];
    }
    [self.navigationController pushViewController:vc animated:YES];
    self.demoViewController = vc;
}

@end
