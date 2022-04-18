//
//  L2DAppAllocator.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DAppAllocator.h"

using namespace Csm;

void *L2DAppAllocator::Allocate(const csmSizeType size) {
    return malloc(size);
}

void L2DAppAllocator::Deallocate(void *memory) {
    free(memory);
}

void *L2DAppAllocator::AllocateAligned(const csmSizeType size, const csmUint32 alignment) {
    size_t offset, shift, alignedAddress;
    void *allocation;
    void **preamble;

    offset = alignment - 1 + sizeof(void *);
    allocation = Allocate(size + static_cast<csmUint32>(offset));
    alignedAddress = reinterpret_cast<size_t>(allocation) + sizeof(void *);
    shift = alignedAddress % alignment;

    if (shift) {
        alignedAddress += (alignment - shift);
    }
    
    preamble = reinterpret_cast<void **>(alignedAddress);
    preamble[-1] = allocation;
    
    return reinterpret_cast<void *>(alignedAddress);
}

void L2DAppAllocator::DeallocateAligned(void *alignedMemory) {
    void **preamble;
    preamble = static_cast<void **>(alignedMemory);
    Deallocate(preamble[-1]);
}
