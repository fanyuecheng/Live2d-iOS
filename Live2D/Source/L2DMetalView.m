//
//  L2DMetalView.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DMetalView.h"

@implementation L2DMetalView - (instancetype)initWithCoder:(NSCoder *)coder {
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

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device {
    if (self = [super initWithFrame:frameRect device:device]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
}

@end
