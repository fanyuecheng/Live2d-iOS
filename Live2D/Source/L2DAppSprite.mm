//
//  L2DAppSprite.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DAppSprite.h"
#import <CubismFramework.hpp>
#import <Rendering/Metal/CubismRenderer_Metal.hpp>
#import "Rendering/Metal/CubismRenderingInstanceSingleton_Metal.h"

typedef struct {
    vector_float4 baseColor;
} BaseColor;

@interface L2DAppSprite()

@property (nonatomic, assign) SpriteRect rect;
@property (nonatomic, strong) id <MTLTexture> texture;
@property (nonatomic, strong) id <MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id <MTLBuffer> fragmentBuffer;

@end

@implementation L2DAppSprite

- (instancetype)initWithRect:(CGRect)cgrect
                     texture:(id<MTLTexture>)texture {
    if (self = [super init]) {
        _rect.left = (cgrect.origin.x - cgrect.size.width * 0.5f);
        _rect.right = (cgrect.origin.x + cgrect.size.width * 0.5f);
        _rect.up = (cgrect.origin.y + cgrect.size.height * 0.5f);
        _rect.down = (cgrect.origin.y - cgrect.size.height * 0.5f);
        _texture = texture;
        _spriteColorR = _spriteColorG = _spriteColorB = _spriteColorA = 1.0f;

        CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
        id <MTLDevice> device = [single getMTLDevice];
        [self setBufferWithDevice:device];
        [self setFunctionWithDevice:device];
    }
    return self;
}

- (void)renderImmidiateWithEncoder:(id<MTLRenderCommandEncoder>)encoder {
    float width = _rect.right - _rect.left;
    float height = _rect.up - _rect.down;
 
    [encoder setFragmentTexture:_texture atIndex:0];
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:_fragmentBuffer offset:0 atIndex:1];
    [encoder setRenderPipelineState:_pipelineState];

    vector_float2 metalUniforms = (vector_float2){width,height};
    [encoder setVertexBytes:&metalUniforms length:sizeof(vector_float2) atIndex:2];

    BaseColor uniform;
    uniform.baseColor = (vector_float4){ _spriteColorR, _spriteColorG, _spriteColorB, _spriteColorA };
    [encoder setFragmentBytes:&uniform length:sizeof(BaseColor) atIndex:2];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
}

- (void)resizeImmidiateWithRect:(CGRect)rect {
    _rect.left = (rect.origin.x - rect.size.width * 0.5f);
    _rect.right = (rect.origin.x + rect.size.width * 0.5f);
    _rect.up = (rect.origin.y + rect.size.height * 0.5f);
    _rect.down = (rect.origin.y - rect.size.height * 0.5f);

    CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
    id <MTLDevice> device = [single getMTLDevice];
    [self setBufferWithDevice:device];
}

- (BOOL)isHitWithPoint:(CGPoint)point {
    return (point.x >= _rect.left &&
            point.x <= _rect.right &&
            point.y >= _rect.down &&
            point.y <= _rect.up);
}

- (void)setColor:(float)r g:(float)g b:(float)b a:(float)a {
    _spriteColorR = r;
    _spriteColorG = g;
    _spriteColorB = b;
    _spriteColorA = a;
}

- (void)setRenderPipelineDescriptorWithDevice:(id<MTLDevice>)device
                                vertexProgram:(id<MTLFunction>)vertexProgram
                              fragmentProgram:(id<MTLFunction>)fragmentProgram {
    MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    descriptor.label                           = @"SpritePipeline";
    descriptor.vertexFunction                  = vertexProgram;
    descriptor.fragmentFunction                = fragmentProgram;
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    descriptor.colorAttachments[0].blendingEnabled = true;
    descriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    descriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    descriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    descriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    [self setRenderPipelineStateWithDevice:device descriptor:descriptor];
}

#pragma mark - Private
 
- (NSString *)getMetalShader {
    NSString *shader =
    @"#include <metal_stdlib>\n"
    "using namespace metal;\n"
    "\n"
    "struct ColorInOut\n"
    "{\n"
    "    float4 position [[ position ]];\n"
    "    float2 texCoords;\n"
    "};\n"
    "\n"
    "struct BaseColor\n"
    "{\n"
    "    float4 color;\n"
    "};\n"
    "\n"
    "vertex ColorInOut vertexShader(constant float4 *positions [[ buffer(0) ]],\n"
    "                               constant float2 *texCoords [[ buffer(1) ]],\n"
    "                                        uint    vid       [[ vertex_id ]])\n"
    "{\n"
    "    ColorInOut out;\n"
    "    out.position = positions[vid];\n"
    "    out.texCoords = texCoords[vid];\n"
    "    return out;\n"
    "}\n"
    "\n"
    "fragment float4 fragmentShader(ColorInOut       in      [[ stage_in ]],\n"
    "                               texture2d<float> texture [[ texture(0) ]],\n"
    "                               constant BaseColor &uniform [[ buffer(2) ]])\n"
    "{\n"
    "    constexpr sampler colorSampler;\n"
    "    float4 color = texture.sample(colorSampler, in.texCoords) * uniform.color;\n"
    "    return color;\n"
    "}\n";
    return shader;
}

- (void)setBufferWithDevice:(id<MTLDevice>)device {
    float width = CGRectGetWidth(UIScreen.mainScreen.bounds);
    float height = CGRectGetHeight(UIScreen.mainScreen.bounds);

    vector_float4 positionVertex[] = {
        {(_rect.left  - width * 0.5f) / (width * 0.5f), (_rect.down - height * 0.5f) / (height * 0.5f), 0, 1},
        {(_rect.right - width * 0.5f) / (width * 0.5f), (_rect.down - height * 0.5f) / (height * 0.5f), 0, 1},
        {(_rect.left  - width * 0.5f) / (width * 0.5f), (_rect.up   - height * 0.5f) / (height * 0.5f), 0, 1},
        {(_rect.right - width * 0.5f) / (width * 0.5f), (_rect.up   - height * 0.5f) / (height * 0.5f), 0, 1}
    };

    vector_float2 uvVertex[] = {
        {0.0f, 1.0f},
        {1.0f, 1.0f},
        {0.0f, 0.0f},
        {1.0f, 0.0f}
    };

    _vertexBuffer = [device newBufferWithBytes:positionVertex
                                        length:sizeof(positionVertex)
                                       options:MTLResourceStorageModeShared];
    _fragmentBuffer = [device newBufferWithBytes:uvVertex
                                          length:sizeof(uvVertex)
                                         options:MTLResourceStorageModeShared];
}

- (void)setFunctionWithDevice:(id <MTLDevice>)device {
    MTLCompileOptions *compileOptions = [MTLCompileOptions new];
    if (@available(iOS 12.0, *)) {
        compileOptions.languageVersion = MTLLanguageVersion2_1;
    }
    NSError *compileError;
    NSString *shader = [self getMetalShader];
    id <MTLLibrary> shaderLib = [device newLibraryWithSource:shader
                                                     options:compileOptions
                                                       error:&compileError];
    if (!shaderLib) {
        NSLog(@"ERROR: Couldnt create a Source shader library");
    }
    id <MTLFunction> vertexProgram = [shaderLib newFunctionWithName:@"vertexShader"];
    if (!vertexProgram) {
        NSLog(@"ERROR: Couldn't load vertex function from default library");
    }
    id <MTLFunction> fragmentProgram = [shaderLib newFunctionWithName:@"fragmentShader"];
    if (!fragmentProgram) {
        NSLog(@"ERROR: Couldn't load fragment function from default library");
    }
    [self setRenderPipelineDescriptorWithDevice:device
                                  vertexProgram:vertexProgram
                                fragmentProgram:fragmentProgram];
}

- (void)setRenderPipelineStateWithDevice:(id<MTLDevice>)device
                              descriptor:(MTLRenderPipelineDescriptor *)descriptor {
    NSError *error;
    _pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"ERROR: Failed aquiring pipeline state: %@", error);
    }
}

@end
