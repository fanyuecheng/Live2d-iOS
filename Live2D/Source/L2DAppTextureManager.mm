//
//  L2DAppTextureManager.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DAppTextureManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <Metal/Metal.h>
#import <iostream>
#define STBI_NO_STDIO
#define STBI_ONLY_PNG
#define STB_IMAGE_IMPLEMENTATION
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#pragma clang diagnostic ignored "-Wunused-function"
#import "stb_image.h"
#pragma clang diagnostic pop
#import "L2DAppPal.h"
#import "Rendering/Metal/CubismRenderingInstanceSingleton_Metal.h"

@interface L2DAppTextureManager ()

@property (nonatomic) Csm::csmVector <TextureInfo *> textures;

@end

@implementation L2DAppTextureManager

- (void)dealloc {
    [self releaseTextures];
}

- (TextureInfo *)createTextureWithPNG:(std::string)fileName {
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++) {
        if (_textures[i]->fileName == fileName) {
            return _textures[i];
        }
    }
    CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
    id <MTLDevice> device = [single getMTLDevice];
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:device];
    NSData *imageData = L2DAppPal::LoadFile(fileName);
    UIImage *image = [UIImage imageWithData:imageData];
    id <MTLTexture> texture = [loader newTextureWithCGImage:image.CGImage options:@{MTKTextureLoaderOptionSRGB : @(NO)} error:nil];
    
    TextureInfo *textureInfo = new TextureInfo;
    textureInfo->fileName = fileName;
    textureInfo->width = image.size.width;
    textureInfo->height = image.size.height;;
    textureInfo->texture = texture;
    _textures.PushBack(textureInfo);

    return textureInfo;

    return textureInfo;
}

- (TextureInfo *)createTextureWithImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    NSString *name = [self md5WithData:data];
    const std::string fileName = [name UTF8String];
    
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++) {
        if (_textures[i]->fileName == fileName) {
            return _textures[i];
        }
    }
    
    int width, height, channels;
    unsigned char *png;
    NSUInteger len = [data length];
    Byte *bytes = (Byte*)malloc(len);
    memcpy(bytes, [data bytes], len);
    
    png = stbi_load_from_memory(bytes,
                                (int)data.length,
                                &width,
                                &height,
                                &channels,
                                STBI_rgb_alpha);

    {
#ifdef PREMULTIPLIED_ALPHA_ENABLE
        unsigned int *fourBytes = reinterpret_cast<unsigned int *>(png);
        for (int i = 0; i < width * height; i++) {
            unsigned char *p = png + i * 4;
            int tes = [self premultiply:p[0] Green:p[1] Blue:p[2] Alpha:p[3]];
            fourBytes[i] = tes;
        }
#endif
    }
    
    MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
    descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    descriptor.width = width;
    descriptor.height = height;

    CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
    id <MTLDevice> device = [single getMTLDevice];
    id <MTLTexture> texture = [device newTextureWithDescriptor:descriptor];

    NSUInteger bytesPerRow = 4 * width;
    MTLRegion region = {
        {0, 0, 0},
        {(NSUInteger)width, (NSUInteger)height, 1}
    };

    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:png
               bytesPerRow:bytesPerRow];
  
    TextureInfo *textureInfo = new TextureInfo;
    textureInfo->fileName = fileName;
    textureInfo->width = width;
    textureInfo->height = height;
    textureInfo->texture = texture;
    _textures.PushBack(textureInfo);

    return textureInfo;
}
 
- (void)releaseTextures {
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++) {
        delete _textures[i];
    }
    _textures.Clear();
}

- (void)releaseTexture:(id <MTLTexture>)texture {
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++) {
        if (_textures[i]->texture != texture) {
            continue;
        }
        delete _textures[i];
        _textures.Remove(i);
        break;
    }
}

- (void)releaseTextureByName:(std::string)fileName {
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++) {
        if (_textures[i]->fileName == fileName) {
            delete _textures[i];
            _textures.Remove(i);
            break;
        }
    }
}

#pragma mark - Private
- (unsigned int)premultiply:(unsigned char)red
                      green:(unsigned char)green
                       blue:(unsigned char)blue
                      alpha:(unsigned char) alpha {
    return static_cast<unsigned>(\
                                 (red * (alpha + 1) >> 8) | \
                                 ((green * (alpha + 1) >> 8) << 8) | \
                                 ((blue * (alpha + 1) >> 8) << 16) | \
                                 (((alpha)) << 24)   \
                                 );
}

- (NSString *)md5WithData:(NSData *)data {
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5, data.bytes, (CC_LONG)data.length);
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02X", digest[i]];
    }
    return result;
}

@end
//for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++) {
//    if (_textures[i]->fileName == fileName) {
//        return _textures[i];
//    }
//}
//
//NSData *imageData = L2DAppPal::LoadFile(fileName);
//UIImage *image = [UIImage imageWithData:imageData];
//
//if (!image) {
//    return nil;
//}
//
//NSData *data = UIImagePNGRepresentation(image);
//
//int width, height, channels;
//unsigned char *png;
//NSUInteger len = [data length];
//Byte *bytes = (Byte*)malloc(len);
//memcpy(bytes, [data bytes], len);
//
//png = stbi_load_from_memory(bytes,
//                            (int)data.length,
//                            &width,
//                            &height,
//                            &channels,
//                            STBI_rgb_alpha);
//
//{
//#ifdef PREMULTIPLIED_ALPHA_ENABLE
//unsigned int *fourBytes = reinterpret_cast<unsigned int *>(png);
//for (int i = 0; i < width * height; i++) {
//    unsigned char *p = png + i * 4;
//    int tes = [self premultiply:p[0] Green:p[1] Blue:p[2] Alpha:p[3]];
//    fourBytes[i] = tes;
//}
//#endif
//}
//
//MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
//descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
//descriptor.width = width;
//descriptor.height = height;
//
//CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
//id <MTLDevice> device = [single getMTLDevice];
//id <MTLTexture> texture = [device newTextureWithDescriptor:descriptor];
//
//NSUInteger bytesPerRow = 4 * width;
//MTLRegion region = {
//    {0, 0, 0},
//    {(NSUInteger)width, (NSUInteger)height, 1}
//};
//
//[texture replaceRegion:region
//           mipmapLevel:0
//             withBytes:png
//           bytesPerRow:bytesPerRow];
//
//TextureInfo *textureInfo = new TextureInfo;
//textureInfo->fileName = fileName;
//textureInfo->width = width;
//textureInfo->height = height;
//textureInfo->texture = texture;
//_textures.PushBack(textureInfo);
//
//free(png);
