//
//  Peer.m
//  SkylinkSample
//
//  Created by Yuxi Liu on 13/9/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import "Peer.h"

@implementation Peer
- (instancetype)initWithPeerID:(NSString *)peerId{
    if (self = [super init]) {
        self.peerId = peerId;
        self.medias = [NSMutableArray new];
    }
    return self;
}
- (instancetype)initWithPeerID:(NSString *)peerId userName:(NSString *)userName videoView:(UIView *)videoView videoSize:(CGSize)videoSize
{
    if (self = [super init]) {
        self.peerId = peerId;
        self.userName = userName;
        self.videoView = videoView;
        self.videoSize = videoSize;
        self.medias = [NSMutableArray new];
    }
    return self;
}
@end
