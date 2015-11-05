//
//  bridge2OpenCV.m
//  cutImageIOS
//
//  Created by vk on 15/8/24.
//  Copyright (c) 2015年 quxiu8. All rights reserved.
//

#import "Bridge2OpenCV.h"
#import <opencv2/opencv.hpp> 
#import "CutoutImagePacking.h"

@interface Bridge2OpenCV ()

@property (nonatomic) CutoutImagePacking *cutoutImagePacking;
@property (nonatomic,strong) UIImage *srcImg;
//@property (nonatomic) CGSize windowSize; //屏幕坐标系大小
@property (nonatomic) float xScale;
@property (nonatomic) float yScale;

@property (assign, nonatomic) int inputMatCols;
@property (assign, nonatomic) int inputMatRows;

@end

@implementation Bridge2OpenCV

-(id)init
{
    if(self = [super init])
    {
        self.cutoutImagePacking = new CutoutImagePacking;//[[CutoutImage alloc]init];
    }
    return self;
}
/**
 *  带有待计算图像的初始化程序
 *
 *  @param setImage 要传入的图像
 *
 *  @return self指针
 */
-(id)initWithImage:(UIImage *)setImage
{
    if(self = [super init])
    {
        self.srcImg = setImage;
        self.cutoutImagePacking = new CutoutImagePacking;//[[CutoutImage alloc]init];
        
        cv::Mat sendImageRGBA = [self CVMat:setImage];
        cv::Mat sendImageBGR;
        cv::cvtColor(sendImageRGBA, sendImageBGR, CV_RGBA2BGR);
        NSLog(@"sendImageBGR.cols = %d",sendImageBGR.cols);
        NSLog(@"sendImageBGR.rows = %d",sendImageBGR.rows);
        self.cutoutImagePacking->setColorImage(sendImageBGR, 20);
    }
    return self;
}
/**
 *  设置待计算的图像，重置内部的所有计算用容器与状态，
 *  此函数被调用意味着1、输入了新图像 2、重置操作
 *
 *  @param setImage 图像输入
 *  @param winSize  外部显示view的窗口大小，用于输入坐标点与图像坐标点的转换
 */
-(void) setCalculateImage:(UIImage *)setImage andWindowSize:(CGSize)winSize
{
    cv::Mat sendImageRGBA = [self CVMat:setImage];
    cv::Mat sendImageBGR;
    cv::cvtColor(sendImageRGBA, sendImageBGR, CV_RGBA2BGR);
    NSLog(@"sendImageBGR.cols = %d",sendImageBGR.cols);
    NSLog(@"sendImageBGR.rows = %d",sendImageBGR.rows);
    self.cutoutImagePacking->setColorImage(sendImageBGR, 20);
    self.inputMatCols = sendImageBGR.cols;
    self.inputMatRows = sendImageBGR.rows;
    [self setScaleWithWindowSize:winSize];
}   

- (void)setScaleWithWindowSize:(CGSize)winSize{
    self.xScale = self.inputMatCols/winSize.width;
    self.yScale = self.inputMatRows/winSize.height;
}

- (void) updateWindowSize:(CGSize) winSize{
    [self setScaleWithWindowSize:winSize];
}

/**
 *  将输入点直接转换成Mask点，其中没有图像算法
 *
 *  @param selectPoint 输入的Mask点坐标
 *  @param lineWidth   要花的线的线宽
 */
-(void) setDrawPoint:(NSMutableArray*)selectPoint andLineWidth:(int)lineWidth
{
    //存储类型转换，nsmutablearray转换为 std::vector
    //printf("lineWidth = %d\n",lineWidth);
    std::vector<cv::Point> sendPoint;
    for(int i =0;i<[selectPoint count];i++){
        NSValue *pv = [selectPoint objectAtIndex:i];
        CGPoint p = [pv CGPointValue];
        NSLog(@" DrawPoint = %@ " , NSStringFromCGPoint(p));
        cv::Point cvp;
        cvp.x = (int)(p.x*self.xScale);
        cvp.y = (int)(p.y*self.yScale);
        sendPoint.push_back(cvp);
    }
    cv::Mat getMat;
    bool haveResultMat;
    self.cutoutImagePacking->drawMask(sendPoint, lineWidth, getMat, haveResultMat);
    cv::cvtColor(getMat, getMat, CV_BGR2RGB);
    UIImage *sendUIImage = [self UIImageFromCVMat:getMat];
    if(self.delegate && [self.delegate respondsToSelector:@selector(resultImageReady:andHaveMaskMat:)]){
        [self.delegate resultImageReady:sendUIImage andHaveMaskMat:haveResultMat];
    }
}
/**
 *  整体生长算法程序入口
 *
 *  @param selectPoint 外部传入的容器，其中包含生长点。
 *  @param lineWidth   线段宽度
 */
-(void) setCreatPoint:(NSMutableArray*)selectPoint andLineWidth:(int)lineWidth
{
    std::vector<cv::Point> sendPoint;
    for(int i =0;i<[selectPoint count];i++){
        NSValue *pv = [selectPoint objectAtIndex:i];
        CGPoint p = [pv CGPointValue];
        cv::Point cvp;
        cvp.x = (int)(p.x*self.xScale);
        cvp.y = (int)(p.y*self.yScale);
        sendPoint.push_back(cvp);
    }
    cv::Mat getMat;
    bool haveResultMat;
    self.cutoutImagePacking->creatMask(sendPoint, lineWidth, getMat, haveResultMat);
    cv::cvtColor(getMat, getMat, CV_BGR2RGB);
    UIImage *sendUIImage = [self UIImageFromCVMat:getMat];
    if(self.delegate && [self.delegate respondsToSelector:@selector(resultImageReady:andHaveMaskMat:)]){
        [self.delegate resultImageReady:sendUIImage andHaveMaskMat:haveResultMat];
    }
    cv::Mat debugMat = self.cutoutImagePacking->getDebugMat();
    cv::Mat debugMat2 = self.cutoutImagePacking->getDebugMat2();
    //UIImage *debugImg = [self UIImageFromCVMat:debugMat];
    //UIImage *debugImg2 = [self UIImageFromCVMat:debugMat2];
}
/**
 *  按滑动位置删除扣取区域的程序入口
 *
 *  @param selectPoint 划屏点容器，待删除点
 *  @param lineWidth   删除线的线段宽度
 */
-(void) setDeletePoint:(NSMutableArray*)selectPoint andLineWidth:(int)lineWidth
{
    std::vector<cv::Point> sendPoint;
    for(int i =0;i<[selectPoint count];i++){
        NSValue *pv = [selectPoint objectAtIndex:i];
        CGPoint p = [pv CGPointValue];
        cv::Point cvp;
        cvp.x = (int)(p.x*self.xScale);
        cvp.y = (int)(p.y*self.yScale);
        sendPoint.push_back(cvp);
    }
    cv::Mat getMat;
    bool haveResultMat;
    self.cutoutImagePacking->deleteMask(sendPoint, lineWidth, getMat, haveResultMat);
    cv::cvtColor(getMat, getMat, CV_BGR2RGB);
    UIImage *sendUIImage = [self UIImageFromCVMat:getMat];
    if(self.delegate && [self.delegate respondsToSelector:@selector(resultImageReady:andHaveMaskMat:)]){
        [self.delegate resultImageReady:sendUIImage andHaveMaskMat:haveResultMat];
    }
}
/**
 *  重置所有生成的mask
 */
-(void) resetAllMask
{
    cv::Mat getMat;
    self.cutoutImagePacking->resetMask(getMat);
    cv::cvtColor(getMat, getMat, CV_BGR2RGB);
    UIImage *sendUIImage = [self UIImageFromCVMat:getMat];
    if(self.delegate && [self.delegate respondsToSelector:@selector(resultImageReady:andHaveMaskMat:)]){
        [self.delegate resultImageReady:sendUIImage andHaveMaskMat:false];
    }
}
/**
 *  回退操作
 */
-(void) redoPoint
{
    cv::Mat getMat;
    bool haveResultMat;
    self.cutoutImagePacking->redo(getMat, haveResultMat);
    cv::cvtColor(getMat, getMat, CV_BGR2RGB);
    UIImage *sendUIImage = [self UIImageFromCVMat:getMat];
    if(self.delegate && [self.delegate respondsToSelector:@selector(resultImageReady:andHaveMaskMat:)]){
        [self.delegate resultImageReady:sendUIImage andHaveMaskMat:haveResultMat];
    }
}
/**
 *  前进操作
 */
-(void) undoPoint
{
    cv::Mat getMat;
    bool haveResultMat;
    self.cutoutImagePacking->undo(getMat,haveResultMat);
    cv::cvtColor(getMat, getMat, CV_BGR2RGB);
    UIImage *sendUIImage = [self UIImageFromCVMat:getMat];
    if(self.delegate && [self.delegate respondsToSelector:@selector(resultImageReady:andHaveMaskMat:)]){
        [self.delegate resultImageReady:sendUIImage andHaveMaskMat:haveResultMat];
    }
}
/**
 *  得到最终的分割结果
 *
 *  @return 输出分割的UIImage
 */
-(UIImage *) getCutResult
{
    cv::Mat cutResultMat = self.cutoutImagePacking->getFinalColorMergeImg();
    NSLog(@" cutResultMat.channels() = %d ",cutResultMat.channels());
    cv::cvtColor(cutResultMat, cutResultMat, CV_BGRA2RGBA);
    UIImage *cutResultUIImage = [self UIImageFromCVMat:cutResultMat];
   
    cutResultUIImage = [self imageBlackToTransparent:cutResultUIImage];
    
    return cutResultUIImage;
}

/**
 *  UIImage转mat，注意。uiimage转换为的cvMat可能是rgba的，所以需要再次修改
 *
 *  @param uiiameg 输入的UIImage
 *
 *  @return 返回的cv::Mat
 */
-(cv::Mat)CVMat:( UIImage *)uiiameg
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(uiiameg.CGImage);
    CGFloat cols = uiiameg.size.width;
    CGFloat rows = uiiameg.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), uiiameg.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
//mat转uiimage,这里注意，
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

-(UIImage *)UIImageFromCVMatWithAlpha:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    NSLog(@"!!!!! %zu",cvMat.elemSize());
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        //kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Little,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

void ProviderReleaseData (void *info, const void *data, size_t size)
{
    free((void*)data);
}

- (UIImage*) imageBlackToTransparent:(UIImage*) image
{
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    //   create context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    // traverse pixe
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++)
    {
//        if ((*pCurPtr & 0xFFFFFF00) == 0xffffff00)    // make white to Transparent
        if ((*pCurPtr & 0xFFFFFF00) == 0x00000000)    // / make black to Transparent
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
        /*
        else
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = 0; //0~255
            ptr[2] = 0;
            ptr[1] = 0;
            
        }
         */
        
    }
    
    // context to image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,
                                        kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    // release
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return resultUIImage;
}

- (UIImage*) imageWhiteToSetColor:(UIImage*) image setColor:(UIColor *) color;
{
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    //   create context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    CGFloat fr,fg,fb,fa;
    [color getRed:&fr green:&fg blue:&fb alpha:&fa];
    // traverse pixe
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++)
    {
        //        if ((*pCurPtr & 0xFFFFFF00) == 0xffffff00)    // make white to Transparent
        if ((*pCurPtr & 0xFFFFFF00) == 0x00000000)    // / make black to Transparent
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
        else {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = (uchar)(fa*255);
            ptr[1] = (uchar)(fb*255);
            ptr[2] = (uchar)(fg*255);
            ptr[3] = (uchar)(fr*255);
        }
    }
    // context to image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,
                                        kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    // release
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return resultUIImage;
}

@end
