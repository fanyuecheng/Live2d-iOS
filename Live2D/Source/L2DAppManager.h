//
//  L2DAppManager.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import <Foundation/Foundation.h>
#import <CubismFramework.hpp>
#import <Math/CubismMatrix44.hpp>
#import <Type/csmVector.hpp>
#import "L2DAppModel.h"
#import "L2DAppTextureManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface L2DAppManager : NSObject

@property (nonatomic, strong) L2DAppTextureManager *textureManager;
@property (nonatomic, strong) NSMutableArray <L2DAppModel *> *modelArray;
@property (nonatomic) Csm::CubismMatrix44 *viewMatrix;
@property (nonatomic) Csm::Rendering::CubismOffscreenFrame_Metal *renderBuffer;
@property (nonatomic) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic) float clearColorR;
@property (nonatomic) float clearColorG;
@property (nonatomic) float clearColorB;

+ (instancetype)sharedInstance;

- (void)initializeCubism;
 
- (void)releaseAllModel;

- (void)onDragWithX:(Csm::csmFloat32)x y:(Csm::csmFloat32)y;

- (void)onTapWithX:(Csm::csmFloat32)x y:(Csm::csmFloat32)y;
 
- (void)onUpdateWithSize:(CGSize)size
                  buffer:(id<MTLCommandBuffer>)commandBuffer
                drawable:(id<CAMetalDrawable>)drawable
                 texture:(id<MTLTexture>)texture;

- (void)setDisplayModel:(L2DAppModel *)model;
  
- (void)setViewMatrix:(Csm::CubismMatrix44 *)m;
 
- (void)setRenderTargetClearColor:(float)r g:(float)g b:(float)b;

@end
 
NS_ASSUME_NONNULL_END
