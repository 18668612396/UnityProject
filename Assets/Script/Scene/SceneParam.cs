using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;


[ExecuteInEditMode]
public class SceneParam : MonoBehaviour
{

    public bool _BigWind;
    bool _tempBigWind;
    private void OnValidate()
    {
        CloudParam();
    }
    private void Update()
    {
        WindParam();
        CloudShadow();
        GrassInteract();
        BigWorldFog();//大世界雾效

    }

    //风力动画参数
    [Range(1.0f, 50.0f)] public float _WindDensity = 20.0f;
    [Range(0.0f, 1.0f)] public float _WindSpeedFloat = 0.0f;
    [Range(0.0f, 1.0f)] public float _WindTurbulenceFloat = 0.0f;
    [Range(0.0f, 1.0f)] public float _WindStrengthFloat = 0.0f;


    private void WindParam()
    {

        Shader.SetGlobalVector("_WindDirection", transform.rotation * Vector3.back);
        Shader.SetGlobalFloat("_WindDensity", _WindDensity);
        Shader.SetGlobalFloat("_WindSpeedFloat", _WindSpeedFloat);
        Shader.SetGlobalFloat("_WindTurbulenceFloat", _WindTurbulenceFloat);
        Shader.SetGlobalFloat("_WindStrengthFloat", _WindStrengthFloat);




    }

    //云阴影参数
    [Range(0.0f, 1.0f)] public float _CloudShadowSize = 0.0f;
    public Vector2 _CloudShadowRadius;
    [Range(0.0f, 1.0f)] public float _CloudShadowIntensity = 1.0f;
    [Range(0.0f, 5.0f)] public float _CloudShadowSpeed = 1.0f;
    private void CloudShadow()
    {

        Shader.SetGlobalFloat("_CloudShadowSize", _CloudShadowSize);
        Shader.SetGlobalVector("_CloudShadowRadius", _CloudShadowRadius);
        Shader.SetGlobalFloat("_CloudShadowSpeed", _CloudShadowSpeed);
        Shader.SetGlobalFloat("_CloudShadowIntensity", _CloudShadowIntensity);

    }
    //草地交互参数
    [Range(0.0f, 5.0f)] public float _InteractRadius;
    [Range(0.0f, 1.0f)] public float _InteractIntensity;
    private void GrassInteract()
    {
        Shader.SetGlobalFloat("_InteractRadius", _InteractRadius);
        Shader.SetGlobalFloat("_InteractIntensity", _InteractIntensity);
    }

    //雾效

    public Color _FogColor;//雾的颜色

    public float _FogGlobalDensity = 2.0f;//雾的密度
    public float _FogHeight = 0.0f;//雾的高度
    public float _FogStartDistance = 10.0f;//雾的开始距离
    public float _FogInscatteringExp = 1.0f;//雾散射指数
    public float _FogGradientDistance = 50.0f;//雾的梯度距离

    private void BigWorldFog()
    {

        Shader.SetGlobalColor("_FogColor", _FogColor);
        Shader.SetGlobalFloat("_FogGlobalDensity", _FogGlobalDensity);
        Shader.SetGlobalFloat("_FogHeight", _FogHeight);
        Shader.SetGlobalFloat("_FogStartDis", _FogStartDistance);
        Shader.SetGlobalFloat("_FogInscatteringExp", _FogInscatteringExp);
        Shader.SetGlobalFloat("_FogGradientDis", _FogGradientDistance);
    }

    private void CloudParam()
    {
        float num = Random.Range(0.0f, 1.0f);

        Shader.SetGlobalFloat("_test", 1);
    }

}
