//
//  L2DViewController.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import <UIKit/UIKit.h>
#import "L2DAppModel.h"
#import "L2DMetalView.h"

NS_ASSUME_NONNULL_BEGIN

@interface L2DViewController : UIViewController <L2DMetalViewDelegate>
 
@property (nonatomic) float clearColorR;
@property (nonatomic) float clearColorG;
@property (nonatomic) float clearColorB;
@property (nonatomic) float clearColorA;
@property (nonatomic) id<MTLCommandQueue> commandQueue;
@property (nonatomic) id<MTLTexture> depthTexture;
 
- (instancetype)initWithModel:(L2DAppModel *)model;

- (void)resizeScreen;
 
- (void)initializeSprite;
 
- (float)transformViewX:(float)deviceX;
 
- (float)transformViewY:(float)deviceY;
 
- (float)transformScreenX:(float)deviceX;
 
- (float)transformScreenY:(float)deviceY;

- (void)setBackgroundImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
