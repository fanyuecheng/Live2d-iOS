//
//  L2DAppModel.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import <Foundation/Foundation.h>
#import "L2DCsmModel.h"
#include <string>

NS_ASSUME_NONNULL_BEGIN

@interface L2DAppModel : NSObject

@property (nonatomic) L2DCsmModel *csmModel;
 
/// model初始化
/// @param path model根目录
/// @param name json name
- (instancetype)initWithDirectory:(NSString *)path
                             name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
