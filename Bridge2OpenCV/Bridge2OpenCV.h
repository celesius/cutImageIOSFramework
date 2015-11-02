//
//  Bridge2OpenCV.h
//  Bridge2OpenCV
//
//  Created by lixu on 15/10/27.
//  Copyright (c) 2015年 lixu. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Bridge2OpenCV.
FOUNDATION_EXPORT double Bridge2OpenCVVersionNumber;

//! Project version string for Bridge2OpenCV.
FOUNDATION_EXPORT const unsigned char Bridge2OpenCVVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Bridge2OpenCV/PublicHeader.h>

#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>

#ifndef Bridge2OpenCV_h
#define Bridge2OpenCV_h

@protocol Bridge2OpenCVDelegate  <NSObject>
-(void) resultImageReady:(UIImage *) sendImage andHaveMaskMat:(bool) have;
@end

@interface Bridge2OpenCV : NSObject
-(id) init;
-(id) initWithImage:(UIImage *)setImage;
-(void) setCalculateImage:(UIImage *)setImage andWindowSize:(CGSize) winSize;
- (void) updateWindowSize:(CGSize) winSize;
-(void) setDrawPoint:(NSMutableArray*)selectPoint andLineWidth:(int)lineWidth;
-(void) setCreatPoint:(NSMutableArray*)selectPoint andLineWidth:(int)lineWidth;
-(void) setDeletePoint:(NSMutableArray*)selectPoint andLineWidth:(int)lineWidth;
-(UIImage *) getCutResult;
-(NSMutableArray *) getMutableCutResult;
-(void) resetAllMask;
-(void) redoPoint;
-(void) undoPoint;

@property (nonatomic,weak) id<Bridge2OpenCVDelegate> delegate;

@end

#endif