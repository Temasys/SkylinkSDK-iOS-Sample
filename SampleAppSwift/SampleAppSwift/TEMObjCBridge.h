//
//  TEMUtil.h
//  SwiftSample
//
//  Created by macbookpro on 19/01/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TEMObjCBridge : NSObject

+ (id)sharedInstance;

- (void)performObjCSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay;
- (BOOL)isSystemVersionGreaterThanOrEqualTo:(NSString*)version;
- (BOOL)isPad;
- (void)try:(void(^)())try catch:(void(^)(NSException*exception))catch finally:(void(^)())finally;
- (BOOL)isImage:(NSString*)extension;
- (BOOL)isMovie:(NSString*)extension;
- (BOOL)removeFileAtPath:(NSString*)filePath;
- (void)saveImageToPhotoAlbum:(UIImage*)image name:(NSString*)filename;

@end