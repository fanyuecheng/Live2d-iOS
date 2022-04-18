//
//  L2DCsmModel.h
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import <Foundation/Foundation.h>
#import "CubismFramework.hpp"
#import "ICubismModelSetting.hpp"
#import <Type/csmRectF.hpp>
#import <Model/CubismUserModel.hpp>
#import <Rendering/Metal/CubismOffscreenSurface_Metal.hpp>

#ifndef L2DCsmModel_h
#define L2DCsmModel_h

class L2DCsmModel : public Csm::CubismUserModel {
public:
    L2DCsmModel();
    
    virtual ~L2DCsmModel();
    
    void LoadAssets(const Csm::csmChar *dir, const Csm::csmChar *fileName);
    
    void ReloadRenderer();
    
    void Update();
    
    void Draw(Csm::CubismMatrix44& matrix);
 
    Csm::CubismMotionQueueEntryHandle StartMotion(const Csm::csmChar *group, Csm::csmInt32 no, Csm::csmInt32 priority, Csm::ACubismMotion::FinishedMotionCallback onFinishedMotionHandler = NULL);
 
    Csm::CubismMotionQueueEntryHandle StartRandomMotion(const Csm::csmChar *group, Csm::csmInt32 priority, Csm::ACubismMotion::FinishedMotionCallback onFinishedMotionHandler = NULL);

    void StartMotion(const Csm::csmChar *expressionID);
    
    void StartExpression(const Csm::csmChar *expressionID);
 
    void StartRandomExpression();
 
    virtual void MotionEventFired(const Live2D::Cubism::Framework::csmString& eventValue);
    
    virtual Csm::csmBool HitTest(const Csm::csmChar *hitAreaName, Csm::csmFloat32 x, Csm::csmFloat32 y);
 
    Csm::Rendering::CubismOffscreenFrame_Metal& GetRenderBuffer();

protected:
    
    void DoDraw();

private:
    
    void SetupModel(Csm::ICubismModelSetting* setting);
 
    void SetupTextures();
 
    void PreloadMotionGroup(const Csm::csmChar* group);
 
    void ReleaseMotionGroup(const Csm::csmChar* group) const;
 
    void ReleaseMotions();
 
    void ReleaseExpressions();

    Csm::ICubismModelSetting* _modelSetting;
    Csm::csmString _modelHomeDir;
    Csm::csmFloat32 _userTimeSeconds;
    Csm::csmVector<Csm::CubismIdHandle> _eyeBlinkIds;
    Csm::csmVector<Csm::CubismIdHandle> _lipSyncIds;
    Csm::csmMap<Csm::csmString, Csm::ACubismMotion*> _motions;
    Csm::csmMap<Csm::csmString, Csm::ACubismMotion*> _expressions;
    Csm::csmVector<Csm::csmRectF> _hitArea;
    Csm::csmVector<Csm::csmRectF> _userArea;
    const Csm::CubismId* _idParamAngleX;
    const Csm::CubismId* _idParamAngleY;
    const Csm::CubismId* _idParamAngleZ;
    const Csm::CubismId* _idParamBodyAngleX;
    const Csm::CubismId* _idParamEyeBallX;
    const Csm::CubismId* _idParamEyeBallY;

    NSMutableArray *_motionNameArray;
    NSMutableArray *_expressionNameArray;
    
    Live2D::Cubism::Framework::Rendering::CubismOffscreenFrame_Metal _renderBuffer;
};

#endif 
