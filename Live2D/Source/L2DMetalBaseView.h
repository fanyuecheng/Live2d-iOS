//
//  L2DMetalBaseView.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

#define RENDER_ON_MAIN_THREAD 1
#define ANIMATION_RENDERING   1
#define AUTOMATICALLY_RESIZE  1

NS_ASSUME_NONNULL_BEGIN

@protocol L2DMetalViewDelegate <NSObject>

- (void)drawableResize:(CGSize)size;

- (void)renderToMetalLayer:(nonnull CALayer *)metalLayer;

@end

@interface L2DMetalBaseView : MTKView
 
@property (nonatomic, weak) id <L2DMetalViewDelegate>viewDelegate;

- (void)render;

#if AUTOMATICALLY_RESIZE
- (void)resizeDrawable:(CGFloat)scaleFactor;
#endif

#if ANIMATION_RENDERING
- (void)stopRenderLoop;
#endif

@end

NS_ASSUME_NONNULL_END
