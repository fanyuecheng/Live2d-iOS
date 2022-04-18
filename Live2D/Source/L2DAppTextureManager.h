//
//  L2DAppTextureManager.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//
 
#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <string>
#import <Type/csmVector.hpp>

typedef struct {
    int width;
    int height;
    id <MTLTexture> _Nullable texture;
    std::string fileName;
} TextureInfo;

NS_ASSUME_NONNULL_BEGIN

@interface L2DAppTextureManager : NSObject

- (unsigned int)premultiply:(unsigned char)red
                      green:(unsigned char)green
                       blue:(unsigned char)blue
                      alpha:(unsigned char) alpha;
 
- (TextureInfo *)createTextureWithPNG:(std::string)fileName;

- (TextureInfo *)createTextureWithImage:(UIImage *)image;

- (void)releaseTextures;
 
- (void)releaseTexture:(id <MTLTexture>)texture;
 
- (void)releaseTextureByName:(std::string)fileName;

@end

NS_ASSUME_NONNULL_END
