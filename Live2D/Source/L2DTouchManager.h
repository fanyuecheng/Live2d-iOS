//
//  L2DTouchManager.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface L2DTouchManager : NSObject

@property (nonatomic, readonly) float startX;
@property (nonatomic, readonly) float startY;
@property (nonatomic, readonly) float deltaX;
@property (nonatomic, readonly) float deltaY;
@property (nonatomic, readonly) float scale;
@property (nonatomic, readonly) float lastTouchDistance;
@property (nonatomic, readonly, getter=getX) float lastX;
@property (nonatomic, readonly, getter=getY) float lastY;
@property (nonatomic, readonly, getter=getX1) float lastX1;
@property (nonatomic, readonly, getter=getY1) float lastY1;
@property (nonatomic, readonly, getter=getX2) float lastX2;
@property (nonatomic, readonly, getter=getY2) float lastY2;

- (void)touchesBeganWithPoint:(CGPoint)point;
 
- (void)touchesMovedWithPoint:(CGPoint)point;
 
- (void)touchesMovedWithPoint:(CGPoint)point
                      another:(CGPoint)another;

- (float)getFlickDistance;

- (float)calculateWithPoint:(CGPoint)point
                    another:(CGPoint)another;
 
- (float)calculateMovingAmount:(float)v1 vector2:(float)v2;

@end

NS_ASSUME_NONNULL_END
