using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class VegetationShaderGUI : ShaderGUI
{
    MaterialProperty _MainTexProp;
    MaterialProperty _CutOffProp;
    MaterialProperty _TopColorProp;
    Vector4 Color01 = Color.white;
    MaterialProperty _DownColorProp;
    Vector4 Color02 = Color.white;
    MaterialProperty _GradientVectorProp;
    Vector4 _Gradient;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)

    {

        MaterialParam(properties);
        LoadParam();
        DrawGUI(materialEditor);
        SaveParam();
    }

    private void MaterialParam(MaterialProperty[] properties)
    {
        _MainTexProp = FindProperty("_MainTex", properties);
        _CutOffProp = FindProperty("_CutOff", properties);
        _TopColorProp = FindProperty("_TopColor", properties);
        _DownColorProp = FindProperty("_DownColor", properties);
        _GradientVectorProp = FindProperty("_GradientVector", properties);
    }

    private void DrawGUI(MaterialEditor materialEditor)
    {
        materialEditor.TexturePropertySingleLine(new GUIContent("MainTex"), _MainTexProp);//绘制主纹理GUI
        EditorGUILayout.BeginHorizontal();
        _Gradient.z = EditorGUILayout.FloatField(_Gradient.z);//绘制渐变高度GUI
        Color01 = EditorGUILayout.ColorField(Color01);//绘制渐变颜色
        EditorGUILayout.MinMaxSlider(ref _Gradient.y, ref _Gradient.x, 0.0f, 1.0f);
        EditorGUILayout.ColorField(Color02);
        EditorGUILayout.EndHorizontal();

    }

    private void LoadParam()
    {
        _Gradient = _GradientVectorProp.vectorValue;
        Color01 = _TopColorProp.vectorValue;
        Color02 = _DownColorProp.vectorValue;
    }
    private void SaveParam()
    {
        _GradientVectorProp.vectorValue = _Gradient;
        // _TopColorProp.vectorValue = Color01;
        // _DownColorProp.vectorValue = Color02;
    }

}
