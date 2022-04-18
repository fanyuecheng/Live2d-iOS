//
//  L2DMetalView.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DMetalView.h"

@implementation L2DMetalView {
    CADisplayLink *_displayLink;

#if !RENDER_ON_MAIN_THREAD
    NSThread *_renderThread;
    BOOL _continueRunLoop;
#endif
}
 
- (void)didMoveToWindow {
    [super didMoveToWindow];
#if ANIMATION_RENDERING
    if (self.window == nil) {
        [_displayLink invalidate];
        _displayLink = nil;
        return;
    }
    [self setupCADisplayLinkForScreen:self.window.screen];
#if RENDER_ON_MAIN_THREAD
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

#else
    @synchronized(self) {
        _continueRunLoop = NO;
    }
    _renderThread =  [[NSThread alloc] initWithTarget:self selector:@selector(runThread) object:nil];
    _continueRunLoop = YES;
    [_renderThread start];

#endif
#endif
    
#if AUTOMATICALLY_RESIZE
    [self resizeDrawable:self.window.screen.nativeScale];
#else
    CGSize defaultDrawableSize = self.bounds.size;
    defaultDrawableSize.width *= self.layer.contentsScale;
    defaultDrawableSize.height *= self.layer.contentsScale;
    [self.delegate drawableResize:defaultDrawableSize];
#endif
}
 
#pragma mark - Render Loop

#if ANIMATION_RENDERING

- (void)setPaused:(BOOL)paused {
    [super setPaused:paused];
    _displayLink.paused = paused;
}

- (void)setupCADisplayLinkForScreen:(UIScreen *)screen {
    [self stopRenderLoop];
    _displayLink = [screen displayLinkWithTarget:self selector:@selector(render)];
    _displayLink.paused = self.paused;
    _displayLink.preferredFramesPerSecond = 60;
}

- (void)stopRenderLoop {
    [_displayLink invalidate];
}

#if !RENDER_ON_MAIN_THREAD
- (void)runThread {
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [_displayLink addToRunLoop:runLoop forMode:@"MetalDisplayLinkMode"];
    BOOL continueRunLoop = YES;
    while (continueRunLoop) {
        @autoreleasepool {
            [runLoop runMode:@"MetalDisplayLinkMode" beforeDate:[NSDate distantFuture]];
        }
        @synchronized(self) {
            continueRunLoop = _continueRunLoop;
        }
    }
}
#endif

#endif
 
#pragma mark - Resizing

#if AUTOMATICALLY_RESIZE
 
- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    [super setContentScaleFactor:contentScaleFactor];
    [self resizeDrawable:self.window.screen.nativeScale];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self resizeDrawable:self.window.screen.nativeScale];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self resizeDrawable:self.window.screen.nativeScale];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self resizeDrawable:self.window.screen.nativeScale];
}

#endif

@end
