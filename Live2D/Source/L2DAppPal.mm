//
//  L2DAppPal.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DAppPal.h" 
#import <stdio.h>
#import <stdlib.h>
#import <stdarg.h>
#import <sys/stat.h>
#import <iostream>
#import <fstream>
#import "L2DAppDefine.h"

using std::endl;
using namespace Csm;
using namespace std; 

double L2DAppPal::s_currentFrame = 0.0;
double L2DAppPal::s_lastFrame = 0.0;
double L2DAppPal::s_deltaTime = 0.0;
L2DResouceType L2DAppPal::s_type = L2DResouceTypeBundle;

csmByte* L2DAppPal::LoadFileAsBytes(const string filePath, csmSizeInt *outSize) {
    int path_i = static_cast<int>(filePath.find_last_of("/")+1);
    int ext_i = static_cast<int>(filePath.find_last_of("."));
    std::string pathName = filePath.substr(0,path_i);
    std::string extName = filePath.substr(ext_i,filePath.size()-ext_i);
    std::string fileName = filePath.substr(path_i,ext_i-path_i);
    
    NSString *pathNameStr = [NSString stringWithUTF8String:pathName.c_str()];
    NSString *extNameStr = [NSString stringWithUTF8String:extName.c_str()];
    NSString *fileNameStr = [NSString stringWithUTF8String:fileName.c_str()];
    
    NSString *path = nil;
    if (s_type == L2DResouceTypeBundle) {
        path = [[NSBundle mainBundle] pathForResource:fileNameStr
                                               ofType:extNameStr
                                          inDirectory:pathNameStr];
        NSLog(@"素材地址 Bundle %@", path);
    } else {
        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        path = [[documentDir stringByAppendingPathComponent:pathNameStr] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", fileNameStr, extNameStr]];
        NSLog(@"素材地址 沙盒 %@", path);
    }
 
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);

    *outSize = static_cast<Csm::csmSizeInt>(len);
    return static_cast<Csm::csmByte*>(byteData);
}

NSData* L2DAppPal::LoadFile(const std::string filePath) {
    int path_i = static_cast<int>(filePath.find_last_of("/")+1);
    int ext_i = static_cast<int>(filePath.find_last_of("."));
    std::string pathName = filePath.substr(0,path_i);
    std::string extName = filePath.substr(ext_i,filePath.size()-ext_i);
    std::string fileName = filePath.substr(path_i,ext_i-path_i);
    
    NSString *pathNameStr = [NSString stringWithUTF8String:pathName.c_str()];
    NSString *extNameStr = [NSString stringWithUTF8String:extName.c_str()];
    NSString *fileNameStr = [NSString stringWithUTF8String:fileName.c_str()];
    
    NSString *path = nil;
    if (s_type == L2DResouceTypeBundle) {
        path = [[NSBundle mainBundle] pathForResource:fileNameStr
                                               ofType:extNameStr
                                          inDirectory:pathNameStr];
        NSLog(@"素材地址 Bundle %@", path);
    } else {
        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        path = [[documentDir stringByAppendingPathComponent:pathNameStr] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", fileNameStr, extNameStr]];
        NSLog(@"素材地址 沙盒 %@", path);
    }
 
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;
}

void L2DAppPal::ReleaseBytes(csmByte *byteData) {
    free(byteData);
}

void L2DAppPal::UpdateTime() {
    NSDate *now = [NSDate date];
    double unixtime = [now timeIntervalSince1970];
    s_currentFrame = unixtime;
    s_deltaTime = s_currentFrame - s_lastFrame;
    s_lastFrame = s_currentFrame;
}

void L2DAppPal::PrintLog(const csmChar *format, ...) {
    va_list args;
    va_start(args, format);
    Csm::csmChar buf[256];
    vsnprintf(buf, sizeof(buf), format, args);
    NSLog(@"[Live2D] %@", [NSString stringWithCString:buf encoding:NSUTF8StringEncoding]);
//    NSLog(@"[Live2D] %@", [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args]);
    va_end(args);
}

void L2DAppPal::PrintMessage(const csmChar *message) {
    PrintLog("%s", message);
}
 
void L2DAppPal::SetResouceType(const L2DResouceType type) {
    s_type = type;
}

