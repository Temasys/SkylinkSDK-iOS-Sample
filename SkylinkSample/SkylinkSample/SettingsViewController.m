//
//  SettingsViewController.m
//  SkylinkSample
//
//  Created by Temasys on 29/08/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "SettingsViewController.h"
#import "HomeViewController.h"
#import "SettingCell.h"
#import "Constant.h"

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *appkey_secret_keys;
@property (nonatomic, strong) NSArray *appkey_secret_values;
@property (nonatomic, strong) NSArray *room_name_keys;
@property (nonatomic, strong) NSArray *room_name_values;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Settings";
//    UINib *nib = [UINib nibWithNibName:@"SettingCell" bundle:nil];
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingCell" bundle:nil] forCellReuseIdentifier:CELL_IDENTIFIER];
    self.appkey_secret_keys = @[@"App Key", @"App Secret"];
    self.appkey_secret_values = @[APP_KEY, APP_SECRET];
    self.room_name_keys = @[@"1-1 video call", @"Multi video call", @"Audio call", @"Messages", @"File transfer", @"Data transfer"];
    self.room_name_values = @[ROOM_ONE_TO_ONE_VIDEO, ROOM_MULTI_VIDEO, ROOM_AUDIO, ROOM_MESSAGES, ROOM_FILE_TRANSFER, ROOM_DATA_TRANSFER];
}

// Room names should not bet set to empty
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return self.appkey_secret_keys.count;
    else return self.room_name_keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingCell";
    SettingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[SettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
//    SettingCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    if (indexPath.section == 0) [cell setupCellWithKey:self.appkey_secret_keys[indexPath.row] value:self.appkey_secret_values[indexPath.row]];
    else [cell setupCellWithKey:self.room_name_keys[indexPath.row] value:self.room_name_values[indexPath.row]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) return @"Skylink developer credentials";
    else return @"Sample room names";
}
@end
