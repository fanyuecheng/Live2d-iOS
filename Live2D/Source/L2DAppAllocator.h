//
//  L2DAppAllocator.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#ifndef L2DAppAllocator_h
#define L2DAppAllocator_h

#import <Foundation/Foundation.h>
#import "CubismFramework.hpp"
#import "ICubismAllocator.hpp"

class L2DAppAllocator : public Csm::ICubismAllocator {
    void *Allocate(const Csm::csmSizeType size);
    void *AllocateAligned(const Csm::csmSizeType size, const Csm::csmUint32 alignment);
    void Deallocate(void *memory);
    void DeallocateAligned(void *alignedMemory);
};

#endif 
