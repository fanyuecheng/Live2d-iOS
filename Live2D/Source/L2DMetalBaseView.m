//
//  L2DMetalBaseView.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DMetalBaseView.h"

@implementation L2DMetalBaseView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self didInitialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    self.backgroundColor = [UIColor whiteColor];
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
}

#pragma mark - Render Loop Control

#if ANIMATION_RENDERING

- (void)stopRenderLoop {
     
}

- (void)dealloc {
    [self stopRenderLoop];
}

#else
#endif

#pragma mark - Resizing

#if AUTOMATICALLY_RESIZE

- (void)resizeDrawable:(CGFloat)scaleFactor {
    CGSize newSize = self.bounds.size;
    newSize.width *= scaleFactor;
    newSize.height *= scaleFactor;
    if (newSize.width <= 0 || newSize.width <= 0) {
        return;
    }

#if RENDER_ON_MAIN_THREAD
    
    if (@available(iOS 13.0, *)) {
        CAMetalLayer *metalLayer = (CAMetalLayer *)self.layer;
        if (newSize.width == metalLayer.drawableSize.width &&
            newSize.height == metalLayer.drawableSize.height) {
            return;
        }
        metalLayer.drawableSize = newSize;
    }
    [_viewDelegate drawableResize:newSize];

#else
    @synchronized(metalLayer)  {
        if (newSize.width == metalLayer.drawableSize.width &&
            newSize.height == metalLayer.drawableSize.height) {
            return;
        }
        metalLayer.drawableSize = newSize;
        [_viewDelegate drawableResize:newSize];
    }
#endif
}

#endif
 
#pragma mark - Drawing

- (void)render {
#if RENDER_ON_MAIN_THREAD
    [_viewDelegate renderToMetalLayer:self.layer];
#else
    @synchronized(self.layer) {
        [_viewDelegate renderToMetalLayer:self.layer];
    }
#endif
}

@end
