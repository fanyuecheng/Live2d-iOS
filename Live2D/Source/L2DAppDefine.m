//
//  L2DAppDefine.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//
#import <UIKit/UIKit.h>

Float32 const L2D_ViewScale = 1.0f;
Float32 const L2D_ViewMaxScale = 2.0f;
Float32 const L2D_ViewMinScale = 0.8f;

Float32 const L2D_ViewLogicalLeft = -1.0f;
Float32 const L2D_ViewLogicalRight = 1.0f;
Float32 const L2D_ViewLogicalBottom = -1.0f;
Float32 const L2D_ViewLogicalTop = 1.0f;

Float32 const L2D_ViewLogicalMaxLeft = -2.0f;
Float32 const L2D_ViewLogicalMaxRight = 2.0f;
Float32 const L2D_ViewLogicalMaxBottom = -2.0f;
Float32 const L2D_ViewLogicalMaxTop = 2.0f;
 
char * const L2D_BackImageName = "background_white.png";
 
char * const L2D_MotionGroupIdle = "Idle";
char * const L2D_MotionGroupTapBody = "TapBody";
char * const L2D_HitAreaNameHead = "Head";
char * const L2D_HitAreaNameBody = "Body";

Float32 const L2D_PriorityNone = 0;
Float32 const L2D_PriorityIdle = 1;
Float32 const L2D_PriorityNormal = 2;
Float32 const L2D_PriorityForce = 3;

BOOL const L2D_DebugLogEnable = YES;
BOOL const L2D_DebugTouchLogEnable = YES;
