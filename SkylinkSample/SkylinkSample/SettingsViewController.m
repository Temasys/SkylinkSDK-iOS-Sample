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
#import "EncryptSecretCell.h"
#import "Constant.h"

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *appkey_secret_keys;
@property (nonatomic, strong) NSArray *appkey_secret_values;
@property (nonatomic, strong) NSArray *room_name_keys;
@property (nonatomic, strong) NSArray *room_name_values;
@end

@implementation SettingsViewController{
    NSArray *_allAppKey;
    NSArray *_msg_encryption_secrets;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Settings";
//    UINib *nib = [UINib nibWithNibName:@"SettingCell" bundle:nil];
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingCell" bundle:nil] forCellReuseIdentifier:CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"EncryptSecretCell" bundle:nil] forCellReuseIdentifier:CELL_IDENTIFIER_ENCRYPT_SECRET];
    self.appkey_secret_keys = @[@"App Key", @"App Secret"];
    self.appkey_secret_values = @[APP_KEY, APP_SECRET];
    self.room_name_keys = @[@"1-1 video call", @"Multi video call", @"Audio call", @"Messages", @"File transfer", @"Data transfer"];
    self.room_name_values = @[ROOM_ONE_TO_ONE_VIDEO, ROOM_MULTI_VIDEO, ROOM_AUDIO, ROOM_MESSAGES, ROOM_FILE_TRANSFER, ROOM_DATA_TRANSFER];
    _allAppKey = [SAConstants.shared.APP_KEYS.allKeys sortedArrayUsingSelector:@selector(compare:)];
    _msg_encryption_secrets = [SAConstants.shared.ENCRYPTION_SECRETS.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

// Room names should not bet set to empty
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return self.appkey_secret_keys.count + 1;
    else if (section == 1) return _msg_encryption_secrets.count;
    else return self.room_name_keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0 && indexPath.row == 2) {
        UITableViewCell *_normalCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        _normalCell.textLabel.text = @"Select App Key";
        _normalCell.textLabel.textColor = [UIColor whiteColor];
        _normalCell.backgroundColor = [UIColor colorWithRed:0.1764705926 green:0.01176470611 blue:0.5607843399 alpha:1];
        return _normalCell;
    }
    
    if (indexPath.section == 0 || indexPath.section == 2) {
        SettingCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
        if (!cell) {
            cell = [[SettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER];
        }
        (indexPath.section == 0) ?
        [cell setupCellWithKey:self.appkey_secret_keys[indexPath.row] value:self.appkey_secret_values[indexPath.row]] :
        [cell setupCellWithKey:self.room_name_keys[indexPath.row] value:self.room_name_values[indexPath.row]];
        return cell;
    }else{
        EncryptSecretCell *_encryptCell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_ENCRYPT_SECRET];
        if (!_encryptCell) {
            _encryptCell = [[EncryptSecretCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER_ENCRYPT_SECRET];
        }
        [_encryptCell setupCell:_msg_encryption_secrets[indexPath.row] secret:SAConstants.shared.ENCRYPTION_SECRETS[_msg_encryption_secrets[indexPath.row]]];
        return _encryptCell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Skylink developer credentials";
    }else if (section == 1){
        return @"Encrypt Secrets";
    } else {
        return @"Room names";
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ((indexPath.section == 0) && (indexPath.row == 2)){
        [self selectAppKey];
    }
}
- (void)selectAppKey{
    UIAlertController *_alert = [UIAlertController alertControllerWithTitle:@"Choose a Secret App" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *_noAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    for (NSString *appKey in _allAppKey) {
        UIAlertAction *_yesAction = [UIAlertAction actionWithTitle:appKey style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self selectedAppKey:appKey];
        }];
        [_alert addAction:_yesAction];
    }
    [_alert addAction:_noAction];
    [self presentViewController:_alert animated:YES completion:nil];
}
- (void)selectedAppKey:(NSString *)key{
    APP_KEY = key;
    APP_SECRET = SAConstants.shared.APP_KEYS[key];
    self.appkey_secret_values = @[APP_KEY, APP_SECRET];
    [self.tableView reloadData];
}
@end
