//
//  L2DViewController.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DViewController.h"
#import "L2DAppPal.h"
#import "L2DAppSprite.h"
#import "L2DAppDefine.h"
#import "L2DAppManager.h"
#import "L2DTouchManager.h"
#import "L2DAppTextureManager.h"
#import "CubismFramework.hpp"
#import <Math/CubismMatrix44.hpp>
#import <Math/CubismViewMatrix.hpp>
#import "Rendering/Metal/CubismRenderingInstanceSingleton_Metal.h"

@interface L2DViewController ()

@property (nonatomic) L2DAppSprite          *background;
@property (nonatomic) L2DTouchManager       *touchManager;
@property (nonatomic) Csm::CubismMatrix44   *deviceToScreen;
@property (nonatomic) Csm::CubismViewMatrix *viewMatrix; 
@property (nonatomic, strong) L2DMetalView  *metalView;
@property (nonatomic, strong) UIImage *backgroundImage;

@end

@implementation L2DViewController

- (void)dealloc {
    _background = nil;
    _metalView = nil;
    delete(_viewMatrix);
    _viewMatrix = nil;
    delete(_deviceToScreen);
    _deviceToScreen = nil;
    _touchManager = nil;
    
    NSLog(@"销毁 class:%@", NSStringFromClass([self class]));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [L2DAppManager.sharedInstance.textureManager releaseTextures];
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self didInitialize];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    [self initializeSprite];
}

- (instancetype)initWithModel:(L2DAppModel *)model {
    if (self = [super init]) {
        [[L2DAppManager sharedInstance] setDisplayModel:model];
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.navigationController) {
        self.metalView.frame = CGRectMake(0, self.view.safeAreaInsets.top, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - self.view.safeAreaInsets.top);
    } else {
        self.metalView.frame = self.view.bounds;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
      
    CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
    id <MTLDevice> device = [single getMTLDevice];
    _metalView = [[L2DMetalView alloc] initWithFrame:CGRectZero device:device];
    _metalView.delegate = self;
    [single setMetalLayer:(CAMetalLayer *)_metalView.layer];
     
    _commandQueue = [device newCommandQueue];
    _clearColorR = _clearColorG = _clearColorB = 1.0f;
    _clearColorA = 0.0f;
    _touchManager = [[L2DTouchManager alloc] init];
    _deviceToScreen = new Live2D::Cubism::Framework::CubismMatrix44();
    _viewMatrix = new Live2D::Cubism::Framework::CubismViewMatrix();
    
    [self.view addSubview:self.metalView];
    [self initializeScreen];
};

#pragma mark - Public
- (void)setBackgroundImage:(UIImage *)image {
    if (_background && _backgroundImage != image) {
        _backgroundImage = image;
        L2DAppTextureManager *textureManager = [L2DAppManager sharedInstance].textureManager;
        float width = CGRectGetWidth(UIScreen.mainScreen.bounds);
        float height = CGRectGetHeight(UIScreen.mainScreen.bounds) - self.view.safeAreaInsets.top;
        
        //背景
        TextureInfo *backgroundInfo = [textureManager createTextureWithImage:image];
        float x = width * 0.5f;
        float y = height * 0.5f;
        float fWidth = static_cast<float>(backgroundInfo->width * 2.0f);
        float fHeight = static_cast<float>(height);
        
        _background = [[L2DAppSprite alloc] initWithRect:CGRectMake(x, y, fWidth, fHeight) texture:backgroundInfo->texture];
    }
}

#pragma mark - Method
- (void)initializeScreen {
    float width = CGRectGetWidth(UIScreen.mainScreen.bounds);
    float height = CGRectGetHeight(UIScreen.mainScreen.bounds) - self.view.safeAreaInsets.top;
    float ratio = static_cast<float>(width) / static_cast<float>(height);
    float left = -ratio;
    float right = ratio;
    float bottom = L2D_ViewLogicalLeft;
    float top = L2D_ViewLogicalRight;
 
    _viewMatrix->SetScreenRect(left, right, bottom, top);
    _viewMatrix->Scale(L2D_ViewScale, L2D_ViewScale);

    _deviceToScreen->LoadIdentity();
    if (width > height) {
        float screenW = fabsf(right - left);
        _deviceToScreen->ScaleRelative(screenW / width, -screenW / width);
    } else {
        float screenH = fabsf(top - bottom);
        _deviceToScreen->ScaleRelative(screenH / height, -screenH / height);
    }
    _deviceToScreen->TranslateRelative(-width * 0.5f, -height * 0.5f);
    _viewMatrix->SetMaxScale(L2D_ViewMaxScale);
    _viewMatrix->SetMinScale(L2D_ViewMinScale);
    _viewMatrix->SetMaxScreenRect(
                                  L2D_ViewLogicalMaxLeft,
                                  L2D_ViewLogicalMaxRight,
                                  L2D_ViewLogicalMaxBottom,
                                  L2D_ViewLogicalMaxTop
                                  );
}

- (void)resizeScreen {
    float width = CGRectGetWidth(UIScreen.mainScreen.bounds);
    float height = CGRectGetHeight(UIScreen.mainScreen.bounds) - self.view.safeAreaInsets.top;
    float ratio = static_cast<float>(width) / static_cast<float>(height);
    float left = -ratio;
    float right = ratio;
    float bottom = L2D_ViewLogicalLeft;
    float top = L2D_ViewLogicalRight;
 
    _viewMatrix->SetScreenRect(left, right, bottom, top);
    _viewMatrix->Scale(L2D_ViewScale, L2D_ViewScale);

    _deviceToScreen->LoadIdentity();
    if (width > height) {
        float screenW = fabsf(right - left);
        _deviceToScreen->ScaleRelative(screenW / width, -screenW / width);
    } else {
        float screenH = fabsf(top - bottom);
        _deviceToScreen->ScaleRelative(screenH / height, -screenH / height);
    }
    _deviceToScreen->TranslateRelative(-width * 0.5f, -height * 0.5f);
    _viewMatrix->SetMaxScale(L2D_ViewMaxScale);
    _viewMatrix->SetMinScale(L2D_ViewMinScale);
    _viewMatrix->SetMaxScreenRect(
                                  L2D_ViewLogicalMaxLeft,
                                  L2D_ViewLogicalMaxRight,
                                  L2D_ViewLogicalMaxBottom,
                                  L2D_ViewLogicalMaxTop
                                  );

#if TARGET_OS_MACCATALYST
    [self resizeSprite:width height:height];
#endif
}

- (void)initializeSprite {
    L2DAppTextureManager *textureManager = [L2DAppManager sharedInstance].textureManager;
    float width = CGRectGetWidth(UIScreen.mainScreen.bounds);
    float height = CGRectGetHeight(UIScreen.mainScreen.bounds) - self.view.safeAreaInsets.top;
    
    //背景
    TextureInfo *backgroundInfo = nil;
    if (self.backgroundImage) {
        [textureManager createTextureWithImage:self.backgroundImage];
    } else {
        std::string imageName = L2D_BackImageName;
        backgroundInfo = [textureManager createTextureWithPNG:imageName];
    }
    float x = width * 0.5f;
    float y = height * 0.5f;
    float fWidth = static_cast<float>(backgroundInfo->width * 2.0f);
    float fHeight = static_cast<float>(height);
    
    _background = [[L2DAppSprite alloc] initWithRect:CGRectMake(x, y, fWidth, fHeight) texture:backgroundInfo->texture];
}

- (void)resizeSprite:(float)width height:(float)height {
    float x = width * 0.5f;
    float y = height * 0.5f;
    float fWidth = static_cast<float>(_background.GetTextureId.width * 2.0f);
    float fHeight = static_cast<float>(height) * 0.95f;
    [_background resizeImmidiateWithRect:CGRectMake(x, y, fWidth, fHeight)];
}
 
- (void)renderSprite:(id<MTLRenderCommandEncoder>)encoder {
    [_background renderImmidiateWithEncoder:encoder];
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size  {
    if ([L2DAppManager sharedInstance].modelArray.count == 0) {
        return;
    }
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:size.width height:size.height mipmapped:false];
    descriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    descriptor.storageMode = MTLStorageModePrivate;

    CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
    id <MTLDevice> device = [single getMTLDevice];
    _depthTexture = [device newTextureWithDescriptor:descriptor];

    [self resizeScreen];
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    if ([L2DAppManager sharedInstance].modelArray.count == 0) {
        return;
    }
    
    L2DAppPal::UpdateTime();

    id <MTLCommandBuffer> buffer = [_commandQueue commandBuffer];
    id <CAMetalDrawable> drawable = nil;
    if (@available(iOS 13.0, *)) {
        CAMetalLayer *metalLayer = (CAMetalLayer *)view.layer;
        drawable = [metalLayer nextDrawable];
    }

    MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor]; 
    descriptor.colorAttachments[0].texture = drawable.texture;
    descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);

    id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:descriptor];
 
    [self renderSprite:encoder];

    [encoder endEncoding];

    L2DAppManager *appManager = [L2DAppManager sharedInstance];
    [appManager setViewMatrix:_viewMatrix];
    [appManager onUpdateWithSize:view.frame.size
                          buffer:buffer
                        drawable:drawable
                         texture:_depthTexture];

    [buffer presentDrawable:drawable];
    [buffer commit];
}

#pragma mark - 屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    [_touchManager touchesBeganWithPoint:point];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    float viewX = [self transformViewX:[_touchManager getX]];
    float viewY = [self transformViewY:[_touchManager getY]];
    [_touchManager touchesMovedWithPoint:point];
    [[L2DAppManager sharedInstance] onDragWithX:viewX y:viewY];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    L2DAppManager *appManager = [L2DAppManager sharedInstance];
    [appManager onDragWithX:0.0f y:0.0f];
    float getX = [_touchManager getX];
    float getY = [_touchManager getY];
    float x = _deviceToScreen->TransformX(getX);
    float y = _deviceToScreen->TransformY(getY);
    if (L2D_DebugTouchLogEnable) {
        L2DAppPal::PrintLog("点击 x:%.2f y:%.2f", x, y);
    }
    [appManager onTapWithX:x y:y];
}

#pragma mark - 坐标换算
- (float)transformViewX:(float)deviceX {
    float screenX = _deviceToScreen->TransformX(deviceX);
    return _viewMatrix->InvertTransformX(screenX);
}

- (float)transformViewY:(float)deviceY {
    float screenY = _deviceToScreen->TransformY(deviceY);
    return _viewMatrix->InvertTransformY(screenY);
}

- (float)transformScreenX:(float)deviceX {
    return _deviceToScreen->TransformX(deviceX);
}

- (float)transformScreenY:(float)deviceY {
    return _deviceToScreen->TransformY(deviceY);
}

- (float)transformTapY:(float)deviceY {
    float height = self.view.frame.size.height - self.view.safeAreaInsets.top;
    return deviceY * -1 + height;
}

 
@end
