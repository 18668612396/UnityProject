using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class SceneParam : MonoBehaviour
{
    [Range(1.0f, 50.0f)] public float _WindDensity = 20.0f;
    [Range(0.0f, 1.0f)] public float _WindSpeedFloat = 0.0f;
    [Range(0.0f, 1.0f)] public float _WindTurbulenceFloat = 0.0f;
    [Range(0.0f, 1.0f)] public float _WindStrengthFloat = 0.0f;
    private void Update()
    {
        WindParam();
    }




    private void WindParam()
    {
        Shader.SetGlobalVector("_WindDirection", transform.rotation * Vector3.back);
        Shader.SetGlobalFloat("_WindDensity", _WindDensity);
        Shader.SetGlobalFloat("_WindSpeedFloat", _WindSpeedFloat);
        Shader.SetGlobalFloat("_WindTurbulenceFloat", _WindTurbulenceFloat);
        Shader.SetGlobalFloat("_WindStrengthFloat", _WindStrengthFloat);

    }
}
