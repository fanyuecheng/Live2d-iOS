//
//  L2DAppSprite.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//
 
#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

typedef struct {
    float left;
    float right;
    float up;
    float down;
} SpriteRect;

NS_ASSUME_NONNULL_BEGIN
  
@interface L2DAppSprite : NSObject

@property (nonatomic, readonly, getter=GetTextureId) id <MTLTexture> texture;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property (nonatomic, assign) float spriteColorR;
@property (nonatomic, assign) float spriteColorG;
@property (nonatomic, assign) float spriteColorB;
@property (nonatomic, assign) float spriteColorA;

- (instancetype)initWithRect:(CGRect)rect
                     texture:(id<MTLTexture>)texture;

- (void)renderImmidiateWithEncoder:(id<MTLRenderCommandEncoder>)encoder;
 
- (void)resizeImmidiateWithRect:(CGRect)rect;
 
- (BOOL)isHitWithPoint:(CGPoint)point;

- (void)setColor:(float)r g:(float)g b:(float)b a:(float)a;

- (void)setRenderPipelineDescriptorWithDevice:(id<MTLDevice>)device
                                vertexProgram:(id<MTLFunction>)vertexProgram
                              fragmentProgram:(id<MTLFunction>)fragmentProgram;

@end

NS_ASSUME_NONNULL_END
