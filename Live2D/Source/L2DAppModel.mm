//
//  L2DAppModel.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DAppModel.h"
#import "L2DAppPal.h"

@interface L2DAppModel ()

@property (nonatomic, copy) NSString     *path;
@property (nonatomic, copy) NSString     *name;
@property (nonatomic, copy) NSDictionary *json;

@end

@implementation L2DAppModel

- (instancetype)initWithDirectory:(NSString *)path
                             name:(NSString *)name {
    if (self = [super init]) {
        self.path = path;
        self.name = [NSString stringWithFormat:@"%@.model3.json", name];
        
        const std::string cStrPath = [self.path UTF8String];
        const std::string cStrName = [self.name UTF8String];
        
        _csmModel = new L2DCsmModel();
        _csmModel->LoadAssets(cStrPath.c_str(), cStrName.c_str());
         
        NSData *jsonData = L2DAppPal::LoadFile([[self.path stringByAppendingPathComponent:self.name] UTF8String]);
        _json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                options:NSJSONReadingAllowFragments
                                                  error:nil];
        
        NSLog(@"_json = %@", _json);
    }
    return self;
}

- (void)dealloc {
    NSLog(@"销毁 class:%@", NSStringFromClass([self class]));
}

@end
