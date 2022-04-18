//
//  L2DAppManager.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DAppManager.h"
#import "L2DAppPal.h"
#import "L2DAppDefine.h"
#import "L2DAppAllocator.h"
#import <Rendering/Metal/CubismRenderer_Metal.hpp>
#import "Rendering/Metal/CubismRenderingInstanceSingleton_Metal.h"

@interface L2DAppManager ()

@property (nonatomic, assign) BOOL cubismDidInitialize;
@property (nonatomic) L2DAppAllocator allocator;
@property (nonatomic) Csm::CubismFramework::Option cubismOption;

@end

@implementation L2DAppManager

void FinishedMotion(Csm::ACubismMotion *self) {
    L2DAppPal::PrintLog("Motion Finished: %x", self);
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static L2DAppManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _textureManager = [[L2DAppTextureManager alloc] init];
        _modelArray = [NSMutableArray array];
        _viewMatrix = new Csm::CubismMatrix44();
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor]; 
        _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.f, 0.f, 0.f, 0.f);
        _renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        _renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
        _renderPassDescriptor.depthAttachment.clearDepth = 1.0;
        CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
        id <MTLDevice> device = MTLCreateSystemDefaultDevice();
        [single setMTLDevice:device];
    }
    return self;
}

- (void)dealloc {
    if (_renderBuffer) {
        _renderBuffer->DestroyOffscreenFrame();
        delete _renderBuffer;
        _renderBuffer = NULL;
    }
    [self releaseAllModel];
}

#pragma mark - Method
- (void)initializeCubism {
    if (!self.cubismDidInitialize) {
        self.cubismDidInitialize = YES;
        
        _cubismOption.LogFunction = L2DAppPal::PrintMessage;
        _cubismOption.LoggingLevel = Live2D::Cubism::Framework::CubismFramework::Option::LogLevel_Debug;
        Csm::CubismFramework::StartUp(&_allocator, &_cubismOption);
        Csm::CubismFramework::Initialize();
        Csm::CubismMatrix44 projection;
        L2DAppPal::UpdateTime();
    }
}
 
- (void)releaseAllModel {
    for (L2DAppModel *model in self.modelArray) {
        delete model.csmModel;
    }
    [self.modelArray removeAllObjects];
}
 
- (void)onDragWithX:(Csm::csmFloat32)x y:(Csm::csmFloat32)y {
    for (int i = 0; i < self.modelArray.count; i++) {
        L2DAppModel *model = self.modelArray[i];
        model.csmModel->SetDragging(x, y);
    }
}

- (void)onTapWithX:(Csm::csmFloat32)x y:(Csm::csmFloat32)y {
    if (L2D_DebugLogEnable) {
        L2DAppPal::PrintLog("点击 point: {x:%.2f y:%.2f}", x, y);
    }
    for (int i = 0; i < self.modelArray.count; i++) {
        if (self.modelArray[i].csmModel->HitTest(L2D_HitAreaNameHead, x, y)) {
            if (L2D_DebugLogEnable) {
                L2DAppPal::PrintLog("hit area: [%s]", L2D_HitAreaNameHead);
            }
            self.modelArray[i].csmModel->StartRandomExpression();
        } else if (self.modelArray[i].csmModel->HitTest(L2D_HitAreaNameBody, x, y)) {
            if (L2D_DebugLogEnable) {
                L2DAppPal::PrintLog("hit area: [%s]", L2D_HitAreaNameBody);
            }
            self.modelArray[i].csmModel->StartRandomMotion(L2D_MotionGroupTapBody, L2D_PriorityNormal, FinishedMotion);
        }
    }
}
 
- (void)onUpdateWithSize:(CGSize)size
                  buffer:(id<MTLCommandBuffer>)commandBuffer
                drawable:(id<CAMetalDrawable>)drawable
                 texture:(id<MTLTexture>)texture {
    float width = size.width ? size.width : CGRectGetWidth(UIScreen.mainScreen.bounds);
    float height = size.height ? size.height : CGRectGetHeight(UIScreen.mainScreen.bounds);

    Csm::CubismMatrix44 projection;
    
    CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
    id <MTLDevice> device = [single getMTLDevice];

    _renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    _renderPassDescriptor.depthAttachment.texture = texture;
 
    Csm::Rendering::CubismRenderer_Metal::StartFrame(device, commandBuffer, _renderPassDescriptor);

    for (Csm::csmUint32 i = 0; i < self.modelArray.count; ++i) {
        L2DCsmModel *model = self.modelArray[i].csmModel;
        if (model->GetModel()->GetCanvasWidth() > 1.0f && width < height) {
            model->GetModelMatrix()->SetWidth(2.0f);
            projection.Scale(1.0f, static_cast<float>(width) / static_cast<float>(height));
        } else {
            projection.Scale(static_cast<float>(height) / static_cast<float>(width), 1.0f);
        }
        if (_viewMatrix != NULL) {
            projection.MultiplyByMatrix(_viewMatrix);
        }
        
        model->Update();
        model->Draw(projection);
    }
}

- (void)setDisplayModel:(L2DAppModel *)model {
    if (model) {
        [self releaseAllModel];
        [self.modelArray insertObject:model atIndex:0];
        float clearColorR = 1.0f;
        float clearColorG = 1.0f;
        float clearColorB = 1.0f;
        [self setRenderTargetClearColor:clearColorR g:clearColorG b:clearColorB];
    }
}
  

- (void)setViewMatrix:(Csm::CubismMatrix44*)m {
    for (int i = 0; i < 16; i++) {
        _viewMatrix->GetArray()[i] = m->GetArray()[i];
    }
}
 
- (void)setRenderTargetClearColor:(float)r g:(float)g b:(float)b {
    _clearColorR = r;
    _clearColorG = g;
    _clearColorB = b;
}

@end
