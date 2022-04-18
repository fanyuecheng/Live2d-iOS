//
//  L2DAppPal.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#ifndef L2DAppPal_h
#define L2DAppPal_h

#import <Foundation/Foundation.h> 
#import <string>
#import "CubismFramework.hpp"

typedef enum : NSUInteger {
    L2DResouceTypeBundle,
    L2DResouceTypeSandbox
} L2DResouceType;

class L2DAppPal {
public:
    static Csm::csmByte *LoadFileAsBytes(const std::string filePath, Csm::csmSizeInt *outSize);
    static NSData *LoadFile(const std::string filePath);
    
    static void ReleaseBytes(Csm::csmByte *byteData);
    
    static double GetDeltaTime() {return s_deltaTime;}
    
    static void UpdateTime();
    
    static void PrintLog(const Csm::csmChar *format, ...);
    
    static void PrintMessage(const Csm::csmChar *message);

    static void SetResouceType(const L2DResouceType type);
    
    static L2DResouceType GetResouceType() {return s_type;}
private:
    static double s_currentFrame;
    static double s_lastFrame;
    static double s_deltaTime; 
    static L2DResouceType s_type;
};

#endif /* LAppPal_h */

 
