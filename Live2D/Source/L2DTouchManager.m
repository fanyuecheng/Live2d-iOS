//
//  L2DTouchManager.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DTouchManager.h"

@interface L2DTouchManager ()

@property (nonatomic, readwrite) float startX;
@property (nonatomic, readwrite) float startY;
@property (nonatomic, readwrite) float lastX;
@property (nonatomic, readwrite) float lastY;
@property (nonatomic, readwrite) float lastX1;
@property (nonatomic, readwrite) float lastY1;
@property (nonatomic, readwrite) float lastX2;
@property (nonatomic, readwrite) float lastY2;
@property (nonatomic, readwrite) float deltaX;
@property (nonatomic, readwrite) float deltaY;
@property (nonatomic, readwrite) float scale;
@property (nonatomic, readwrite) float lastTouchDistance;

@end

@implementation L2DTouchManager

- (void)touchesBeganWithPoint:(CGPoint)point {
    _lastX = point.x;
    _lastY = point.y;
    _startX = point.x;
    _startY = point.y;
    _lastTouchDistance = -1.0f;
}

- (void)touchesMovedWithPoint:(CGPoint)point {
    _lastX = point.x;
    _lastY = point.y;
    _lastTouchDistance = -1.0f;
}

- (void)touchesMovedWithPoint:(CGPoint)point
                      another:(CGPoint)another {
    float distance = [self calculateWithPoint:point another:another];
    float centerX = (point.x + another.x) * 0.5f;
    float centerY = (point.y + another.y) * 0.5f;

    if (_lastTouchDistance > 0.0f) {
        _scale = powf(distance / _lastTouchDistance, 0.75f);
        _deltaX = [self calculateMovingAmount:point.x - _lastX1 vector2:another.x - _lastX2];
        _deltaY = [self calculateMovingAmount:point.y - _lastY1 vector2:another.y - _lastY2];
    } else {
        _scale = 1.0f;
        _deltaX = 0.0f;
        _deltaY = 0.0f;
    }
    _lastX = centerX;
    _lastY = centerY;
    _lastX1 = point.x;
    _lastY1 = point.y;
    _lastX2 = another.x;
    _lastY2 = another.y;
    _lastTouchDistance = distance;
}

- (float)getFlickDistance {
    return [self calculateWithPoint:CGPointMake(_startX, _startY) another:CGPointMake(_lastX, _lastY)];
}

- (float)calculateWithPoint:(CGPoint)point
                    another:(CGPoint)another {
    return sqrtf((point.x - another.x) * (point.x - another.x) + (point.y - another.y) * (point.y - another.y));
}

- (float)calculateMovingAmount:(float)v1 vector2:(float)v2 {
    if ((v1 > 0.0f) != (v2 > 0.0f)) {
        return 0.0f;
    }
    float sign = v1 > 0.0f ? 1.0f : -1.0f;
    float absoluteValue1 = fabsf(v1);
    float absoluteValue2 = fabsf(v2);
    return sign * ((absoluteValue1 < absoluteValue2) ? absoluteValue1 : absoluteValue2);
}


@end
