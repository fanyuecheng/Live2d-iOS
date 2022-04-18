//
//  L2DCsmModel.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "L2DCsmModel.h"
#import <fstream>
#import <vector>
#import "L2DAppPal.h"
#import "L2DAppDefine.h"
#import "L2DAppManager.h"
#import "L2DAppTextureManager.h"
#import "CubismDefaultParameterId.hpp"
#import "CubismModelSettingJson.hpp"
#import <Utils/CubismString.hpp>
#import <Id/CubismIdManager.hpp>
#import <Motion/CubismMotion.hpp>
#import <Physics/CubismPhysics.hpp>
#import <Motion/CubismMotionQueueEntry.hpp>
#import <Rendering/Metal/CubismRenderer_Metal.hpp>

using namespace Live2D::Cubism::Framework;
using namespace Live2D::Cubism::Framework::DefaultParameterId;

namespace {
    csmByte *CreateBuffer(const csmChar *path, csmSizeInt *size) {
        if (L2D_DebugLogEnable) {
            L2DAppPal::PrintLog("初始化 buffer: %s %d", path, size);
        }
        return L2DAppPal::LoadFileAsBytes(path, size);
    }

    void DeleteBuffer(csmByte *buffer, const csmChar *path = "") {
        if (L2D_DebugLogEnable) {
            L2DAppPal::PrintLog("删除 buffer: %s", path);
        }
        L2DAppPal::ReleaseBytes(buffer);
    }
}

L2DCsmModel::L2DCsmModel() : CubismUserModel(), _modelSetting(NULL), _userTimeSeconds(0.0f) {
    if (L2D_DebugLogEnable) {
        _debugMode = true;
    }
    _idParamAngleX = CubismFramework::GetIdManager()->GetId(ParamAngleX);
    _idParamAngleY = CubismFramework::GetIdManager()->GetId(ParamAngleY);
    _idParamAngleZ = CubismFramework::GetIdManager()->GetId(ParamAngleZ);
    _idParamBodyAngleX = CubismFramework::GetIdManager()->GetId(ParamBodyAngleX);
    _idParamEyeBallX = CubismFramework::GetIdManager()->GetId(ParamEyeBallX);
    _idParamEyeBallY = CubismFramework::GetIdManager()->GetId(ParamEyeBallY);
}

L2DCsmModel::~L2DCsmModel() {
    _renderBuffer.DestroyOffscreenFrame();

    ReleaseMotions();
    ReleaseExpressions();

    for (csmInt32 i = 0; i < _modelSetting->GetMotionGroupCount(); i++) {
        const csmChar *group = _modelSetting->GetMotionGroupName(i);
        ReleaseMotionGroup(group);
    }
    delete _modelSetting;
}

void L2DCsmModel::LoadAssets(const csmChar *dir, const csmChar *fileName) {
    _modelHomeDir = dir;

    if (_debugMode) {
        L2DAppPal::PrintLog("加载模型设置 : %s %s", dir, fileName);
    }

    csmSizeInt size;
    const csmString dirPath = csmString(dir);
    const csmString filePath = csmString(fileName);
    const csmString path = dirPath + csmString("/") + filePath;

    csmByte* buffer = CreateBuffer(path.GetRawString(), &size);
    ICubismModelSetting *setting = new CubismModelSettingJson(buffer, size);
    DeleteBuffer(buffer, path.GetRawString());

    SetupModel(setting);

    CreateRenderer();

    SetupTextures();
}
 
void L2DCsmModel::SetupModel(ICubismModelSetting *setting) {
    _updating = true;
    _initialized = false;

    _modelSetting = setting;

    csmByte *buffer;
    csmSizeInt size;
 
    if (strcmp(_modelSetting->GetModelFileName(), "") != 0) {
        csmString path = _modelSetting->GetModelFileName();
        path = _modelHomeDir + csmString("/") + path;

        if (_debugMode) {
            L2DAppPal::PrintLog("初始化模型: %s", setting->GetModelFileName());
        }
        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadModel(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    if (_modelSetting->GetExpressionCount() > 0) {
        _motionNameArray = [NSMutableArray array];
        
        const csmInt32 count = _modelSetting->GetExpressionCount();
        for (csmInt32 i = 0; i < count; i++) {
            csmString name = _modelSetting->GetExpressionName(i);
            csmString path = _modelSetting->GetExpressionFileName(i);
            path = _modelHomeDir + csmString("/") + path;

            buffer = CreateBuffer(path.GetRawString(), &size);
            ACubismMotion* motion = LoadExpression(buffer, size, name.GetRawString());

            if (_expressions[name] != NULL) {
                ACubismMotion::Delete(_expressions[name]);
                _expressions[name] = NULL;
            }
            _expressions[name] = motion;
            DeleteBuffer(buffer, path.GetRawString());
            [_motionNameArray addObject:[NSString stringWithUTF8String:name.GetRawString()]];
        }
    }
 
    if (strcmp(_modelSetting->GetPhysicsFileName(), "") != 0) {
        csmString path = _modelSetting->GetPhysicsFileName();
        path = _modelHomeDir + csmString("/") + path;

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadPhysics(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }
 
    if (strcmp(_modelSetting->GetPoseFileName(), "") != 0) {
        csmString path = _modelSetting->GetPoseFileName();
        path = _modelHomeDir + csmString("/") + path;

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadPose(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }
 
    if (_modelSetting->GetEyeBlinkParameterCount() > 0) {
        _eyeBlink = CubismEyeBlink::Create(_modelSetting);
    }
  
    {
        _breath = CubismBreath::Create();

        csmVector<CubismBreath::BreathParameterData> breathParameters;

        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleX, 0.0f, 15.0f, 6.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleY, 0.0f, 8.0f, 3.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleZ, 0.0f, 10.0f, 5.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamBodyAngleX, 0.0f, 4.0f, 15.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(CubismFramework::GetIdManager()->GetId(ParamBreath), 0.5f, 0.5f, 3.2345f, 0.5f));

        _breath->SetParameters(breathParameters);
    }
 
    if (strcmp(_modelSetting->GetUserDataFile(), "") != 0) {
        csmString path = _modelSetting->GetUserDataFile();
        path = _modelHomeDir + csmString("/") + path;
        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadUserData(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }
 
    {
        csmInt32 eyeBlinkIdCount = _modelSetting->GetEyeBlinkParameterCount();
        for (csmInt32 i = 0; i < eyeBlinkIdCount; ++i) {
            _eyeBlinkIds.PushBack(_modelSetting->GetEyeBlinkParameterId(i));
        }
    }
 
    {
        csmInt32 lipSyncIdCount = _modelSetting->GetLipSyncParameterCount();
        for (csmInt32 i = 0; i < lipSyncIdCount; ++i) {
            _lipSyncIds.PushBack(_modelSetting->GetLipSyncParameterId(i));
        }
    }
 
    csmMap<csmString, csmFloat32> layout;
    _modelSetting->GetLayoutMap(layout);
    _modelMatrix->SetupFromLayout(layout);

    _model->SaveParameters();

    _motionNameArray = [NSMutableArray array];
    for (csmInt32 i = 0; i < _modelSetting->GetMotionGroupCount(); i++) {
        const csmChar* group = _modelSetting->GetMotionGroupName(i);
        PreloadMotionGroup(group);
    }

    _motionManager->StopAllMotions();

    _updating = false;
    _initialized = true;
}

void L2DCsmModel::PreloadMotionGroup(const csmChar *group) {
    const csmInt32 count = _modelSetting->GetMotionCount(group);

    for (csmInt32 i = 0; i < count; i++) {
        csmString name = Utils::CubismString::GetFormatedString("%s_%d", group, i);
        csmString path = _modelSetting->GetMotionFileName(group, i);
        path = _modelHomeDir + csmString("/") + path;

        if (_debugMode) {
            L2DAppPal::PrintLog("加载表情: %s => [%s_%d] ", path.GetRawString(), group, i);
        }

        csmByte *buffer;
        csmSizeInt size;
        buffer = CreateBuffer(path.GetRawString(), &size);
        CubismMotion* tmpMotion = static_cast<CubismMotion *>(LoadMotion(buffer, size, name.GetRawString()));

        csmFloat32 fadeTime = _modelSetting->GetMotionFadeInTimeValue(group, i);
        if (fadeTime >= 0.0f) {
            tmpMotion->SetFadeInTime(fadeTime);
        }

        fadeTime = _modelSetting->GetMotionFadeOutTimeValue(group, i);
        if (fadeTime >= 0.0f) {
            tmpMotion->SetFadeOutTime(fadeTime);
        }
        tmpMotion->SetEffectIds(_eyeBlinkIds, _lipSyncIds);

        if (_motions[name] != NULL) {
            ACubismMotion::Delete(_motions[name]);
        }
        _motions[name] = tmpMotion;

        DeleteBuffer(buffer, path.GetRawString());
        
        [_motionNameArray addObject:[NSString stringWithUTF8String:name.GetRawString()]];
    }
}

void L2DCsmModel::ReleaseMotionGroup(const csmChar *group) const {
    const csmInt32 count = _modelSetting->GetMotionCount(group);
    for (csmInt32 i = 0; i < count; i++) {
        csmString voice = _modelSetting->GetMotionSoundFileName(group, i);
        if (strcmp(voice.GetRawString(), "") != 0) {
            csmString path = voice;
            path = _modelHomeDir + csmString("/") + path;
        }
    }
}

void L2DCsmModel::ReleaseMotions() {
    for (csmMap<csmString, ACubismMotion *>::const_iterator iter = _motions.Begin(); iter != _motions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _motions.Clear();
    [_motionNameArray removeAllObjects];
}

void L2DCsmModel::ReleaseExpressions() {
    for (csmMap<csmString, ACubismMotion *>::const_iterator iter = _expressions.Begin(); iter != _expressions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _expressions.Clear();
    [_expressionNameArray removeAllObjects];
}

void L2DCsmModel::Update() {
    const csmFloat32 deltaTimeSeconds = L2DAppPal::GetDeltaTime();
    _userTimeSeconds += deltaTimeSeconds;
    _dragManager->Update(deltaTimeSeconds);
    _dragX = _dragManager->GetX();
    _dragY = _dragManager->GetY();
    csmBool motionUpdated = false;
    
    _model->LoadParameters();
    if (_motionManager->IsFinished()) {
        //随机
        StartRandomMotion(L2D_MotionGroupIdle, L2D_PriorityIdle);
    } else {
        //继续
        motionUpdated = _motionManager->UpdateMotion(_model, deltaTimeSeconds);
    }
    _model->SaveParameters();
    if (!motionUpdated) {
        if (_eyeBlink != NULL) {
            _eyeBlink->UpdateParameters(_model, deltaTimeSeconds);
        }
    }
    if (_expressionManager != NULL) {
        _expressionManager->UpdateMotion(_model, deltaTimeSeconds);
    }
 
    _model->AddParameterValue(_idParamAngleX, _dragX * 30);
    _model->AddParameterValue(_idParamAngleY, _dragY * 30);
    _model->AddParameterValue(_idParamAngleZ, _dragX * _dragY * -30);
    _model->AddParameterValue(_idParamBodyAngleX, _dragX * 10);
    _model->AddParameterValue(_idParamEyeBallX, _dragX);
    _model->AddParameterValue(_idParamEyeBallY, _dragY);
 
    if (_breath != NULL) {
        _breath->UpdateParameters(_model, deltaTimeSeconds);
    }
 
    if (_physics != NULL) {
        _physics->Evaluate(_model, deltaTimeSeconds);
    }
 
    if (_lipSync) {
        csmFloat32 value = 0;
        for (csmUint32 i = 0; i < _lipSyncIds.GetSize(); ++i) {
            _model->AddParameterValue(_lipSyncIds[i], value, 0.8f);
        }
    }
 
    if (_pose != NULL) {
        _pose->UpdateParameters(_model, deltaTimeSeconds);
    }

    _model->Update();
}

void L2DCsmModel::DoDraw() {
    if (_model == NULL) {
        return;
    }
    GetRenderer<Rendering::CubismRenderer_Metal>()->DrawModel();
}

void L2DCsmModel::Draw(CubismMatrix44& matrix) {
    if (_model == NULL) {
        return;
    }
    matrix.MultiplyByMatrix(_modelMatrix);
    GetRenderer<Rendering::CubismRenderer_Metal>()->SetMvpMatrix(&matrix);
    DoDraw();
}

csmBool L2DCsmModel::HitTest(const csmChar *hitAreaName, csmFloat32 x, csmFloat32 y) {
    if (_opacity < 1) {
        return false;
    }
    const csmInt32 count = _modelSetting->GetHitAreasCount();
    for (csmInt32 i = 0; i < count; i++) {
        if (strcmp(_modelSetting->GetHitAreaName(i), hitAreaName) == 0) {
            const CubismIdHandle drawID = _modelSetting->GetHitAreaId(i);
            return IsHit(drawID, x, y);
        }
    }
    return false;
}

void L2DCsmModel::StartExpression(const csmChar *expressionID) {
    ACubismMotion *motion = _expressions[expressionID];
    if (_debugMode) {
        L2DAppPal::PrintLog("expressionid: [%s]", expressionID);
    }

    if (motion != NULL) {
        _expressionManager->StartMotionPriority(motion, false, L2D_PriorityForce);
    } else {
        if (_debugMode) {
            L2DAppPal::PrintLog("expression[%s]是空 ", expressionID);
        }
    }
}

void L2DCsmModel::StartRandomExpression() {
    if (_expressions.GetSize() == 0) {
        return;
    }

    csmInt32 no = rand() % _expressions.GetSize();
    csmMap<csmString, ACubismMotion *>::const_iterator map_ite;
    csmInt32 i = 0;
    for (map_ite = _expressions.Begin(); map_ite != _expressions.End(); map_ite++) {
        if (i == no) {
            csmString name = (*map_ite).First;
            StartExpression(name.GetRawString());
            return;
        }
        i++;
    }
}

void L2DCsmModel::StartMotion(const csmChar *name) {
    CubismMotion *motion = static_cast<CubismMotion *>(_motions[name]);
    if (_debugMode) {
        L2DAppPal::PrintLog("motionid: [%s]", name);
    }

    if (motion != NULL) {
        _motionManager->StartMotionPriority(motion, false, 1);
    } else {
        if (_debugMode) {
            L2DAppPal::PrintLog("motion[%s]是空 ", name);
        }
    }
}

CubismMotionQueueEntryHandle L2DCsmModel::StartMotion(const csmChar *group, csmInt32 no, csmInt32 priority, ACubismMotion::FinishedMotionCallback onFinishedMotionHandler) {
    if (priority == L2D_PriorityForce) {
        _motionManager->SetReservePriority(priority);
    } else if (!_motionManager->ReserveMotion(priority)) {
        if (_debugMode) {
            L2DAppPal::PrintLog("Motion开始失败");
        }
        return InvalidMotionQueueEntryHandleValue;
    }

    const csmString fileName = _modelSetting->GetMotionFileName(group, no);
 
    csmString name = Utils::CubismString::GetFormatedString("%s_%d", group, no);
    CubismMotion *motion = static_cast<CubismMotion *>(_motions[name.GetRawString()]);
    csmBool autoDelete = false;

    if (motion == NULL) {
        csmString path = fileName;
        path = _modelHomeDir + csmString("/") + path;

        csmByte *buffer;
        csmSizeInt size;
        buffer = CreateBuffer(path.GetRawString(), &size);
        motion = static_cast<CubismMotion *>(LoadMotion(buffer, size, NULL, onFinishedMotionHandler));
        csmFloat32 fadeTime = _modelSetting->GetMotionFadeInTimeValue(group, no);
        if (fadeTime >= 0.0f) {
            motion->SetFadeInTime(fadeTime);
        }
        fadeTime = _modelSetting->GetMotionFadeOutTimeValue(group, no);
        if (fadeTime >= 0.0f) {
            motion->SetFadeOutTime(fadeTime);
        }
        motion->SetEffectIds(_eyeBlinkIds, _lipSyncIds);
        autoDelete = true;
        DeleteBuffer(buffer, path.GetRawString());
    } else {
        motion->SetFinishedMotionHandler(onFinishedMotionHandler);
    }
 
    csmString voice = _modelSetting->GetMotionSoundFileName(group, no);
    if (strcmp(voice.GetRawString(), "") != 0) {
        csmString path = voice;
        path = _modelHomeDir + csmString("/") + path;
    }

    if (_debugMode) {
        L2DAppPal::PrintLog("Motion开始: [%s_%d]", group, no);
    }
    
    return _motionManager->StartMotionPriority(motion, autoDelete, priority);
}

CubismMotionQueueEntryHandle L2DCsmModel::StartRandomMotion(const csmChar *group, csmInt32 priority, ACubismMotion::FinishedMotionCallback onFinishedMotionHandler) {
    if (_modelSetting->GetMotionCount(group) == 0) {
        return InvalidMotionQueueEntryHandleValue;
    }
    csmInt32 no = rand() % _modelSetting->GetMotionCount(group);
   
    return StartMotion(group, no, priority, onFinishedMotionHandler);
    
//    csmChar* name = (csmChar*)[_motionNameArray[no] cStringUsingEncoding:NSASCIIStringEncoding];
//    StartMotion(name);
//    return nil;
}


void L2DCsmModel::ReloadRenderer() {
    DeleteRenderer();
    CreateRenderer();
    SetupTextures();
}

void L2DCsmModel::SetupTextures() {
    for (csmInt32 modelTextureNumber = 0; modelTextureNumber < _modelSetting->GetTextureCount(); modelTextureNumber++) {
            if (strcmp(_modelSetting->GetTextureFileName(modelTextureNumber), "") == 0) {
                continue;
            }
 
            csmString texturePath = _modelSetting->GetTextureFileName(modelTextureNumber);
            texturePath = _modelHomeDir + csmString("/") + texturePath;
            TextureInfo *info = [[L2DAppManager sharedInstance].textureManager createTextureWithPNG:texturePath.GetRawString()];
            id <MTLTexture> mtlTextueNumber = info->texture;
 
            GetRenderer<Rendering::CubismRenderer_Metal>()->BindTexture(modelTextureNumber, mtlTextueNumber);
        }
}

void L2DCsmModel::MotionEventFired(const csmString& eventValue) {
    CubismLogInfo("%s is fired on L2DCsmModel!!", eventValue.GetRawString());
}

Csm::Rendering::CubismOffscreenFrame_Metal& L2DCsmModel::GetRenderBuffer() {
    return _renderBuffer;
}
