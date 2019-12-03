//
//  Peer.h
//  SkylinkSample
//
//  Created by Yuxi Liu on 13/9/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SKYLINK/SKYLINK.h>
NS_ASSUME_NONNULL_BEGIN

@interface Peer : NSObject
@property(nonatomic, copy) NSString *peerId;
@property(nonatomic, copy) NSString *userName;
@property(nonatomic, weak) UIView *videoView;
@property(nonatomic, assign) CGSize videoSize;
@property(nonatomic, strong) NSMutableArray<SKYLINKMedia*> *medias;
- (instancetype)initWithPeerID:(NSString *)peerId;
- (instancetype)initWithPeerID:(NSString *)peerId userName:(NSString *)userName videoView:(UIView *)videoView videoSize:(CGSize)videoSize;
@end

NS_ASSUME_NONNULL_END
