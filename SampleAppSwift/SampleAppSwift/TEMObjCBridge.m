//
//  TEMUtil.m
//  SwiftSample
//
//  Created by macbookpro on 19/01/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TEMObjCBridge.h"

// Macro for version checking
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation TEMObjCBridge

+ (id)sharedInstance {
    static TEMObjCBridge *sharedInstance = nil;
    @synchronized(self) {
        if (sharedInstance == nil)
            sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (void)performObjCSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay
{
    [super performSelector:aSelector withObject:anArgument afterDelay:delay];
}

- (BOOL)isSystemVersionGreaterThanOrEqualTo:(NSString*)version
{
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0");
}

- (BOOL)isPad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

- (void)try:(void(^)())try catch:(void(^)(NSException*exception))catch finally:(void(^)())finally {
    @try {
        try ? try() : nil;
    }
    @catch (NSException *exception) {
        catch ? catch(exception) : nil;
    }
    @finally {
        finally ? finally() : nil;
    }
}

- (BOOL)isImage:(NSString*)extension
{
    return ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpe"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jfif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jfi"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jp2"] == NSOrderedSame || [extension caseInsensitiveCompare:@"j2k"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpf"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpx"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpm"] == NSOrderedSame || [extension caseInsensitiveCompare:@"tiff"] == NSOrderedSame || [extension caseInsensitiveCompare:@"tif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"pict"] == NSOrderedSame || [extension caseInsensitiveCompare:@"pct"] == NSOrderedSame || [extension caseInsensitiveCompare:@"pic"] == NSOrderedSame || [extension caseInsensitiveCompare:@"gif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"png"] == NSOrderedSame || [extension caseInsensitiveCompare:@"qtif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"icns"] == NSOrderedSame || [extension caseInsensitiveCompare:@"bmp"] == NSOrderedSame || [extension caseInsensitiveCompare:@"bmpf"] == NSOrderedSame || [extension caseInsensitiveCompare:@"ico"] == NSOrderedSame || [extension caseInsensitiveCompare:@"cur"] == NSOrderedSame || [extension caseInsensitiveCompare:@"xbm"] == NSOrderedSame);
}

- (BOOL)isMovie:(NSString*)extension
{
    return ([extension caseInsensitiveCompare:@"mpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mpeg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"m1v"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mpv"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3gp"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3gpp"] == NSOrderedSame || [extension caseInsensitiveCompare:@"sdv"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3g2"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3gp2"] == NSOrderedSame || [extension caseInsensitiveCompare:@"m4v"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mp4"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mov"] == NSOrderedSame || [extension caseInsensitiveCompare:@"qt"] == NSOrderedSame);
}

- (BOOL)removeFileAtPath:(NSString*)filePath
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"%s::Error while removing '%@'->%@", __FUNCTION__, filePath, error.localizedDescription);
        return false;
    } else {
        return true;
    }
}

- (void)saveImageToPhotoAlbum:(UIImage*)image name:(NSString*)filename
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)(filename));
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"%s::Error while saving '%@'->%@", __FUNCTION__, contextInfo, error.localizedDescription);
        
        NSLog(@"%s::Now try saving to the Documents Directory", __FUNCTION__);
        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:(__bridge NSString *)(contextInfo)];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
        
        NSError *wError;
        [UIImagePNGRepresentation(image) writeToFile:filePath options:NSDataWritingAtomic error:&wError];
        if (wError)
            NSLog(@"%s::Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
    } else {
        NSLog(@"%s::Image saved successfully", __FUNCTION__);
    }
}

@end
