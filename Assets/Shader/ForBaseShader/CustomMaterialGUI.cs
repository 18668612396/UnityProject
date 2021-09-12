using UnityEngine;
using UnityEditor;

public class CustomMaterialGUI : ShaderGUI
{
    Material material;
    bool isVectorEnbled;
    MaterialProperty toggleProp;
    MaterialProperty floatProp;
    MaterialProperty rangeProp;
    MaterialProperty vecotrProp;//这里是必须要定义的 我觉得是用来转换的中间变量
    MaterialProperty colorProp;
    MaterialProperty MainTexProp;

    int VecotrPropX;
    float VecotrPropY, VecotrPropZ, VecotrPropW;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //获取当前材质球
        material = materialEditor.target as Material;

        //获取相应的属性 前面是Shader内的参数名  后面是这个参数的来源

        floatProp = FindProperty("_Float", properties);
        rangeProp = FindProperty("_Range", properties);
        vecotrProp = FindProperty("_Vector", properties);//这里是将值传输到shader里
        colorProp = FindProperty("_BaseColor", properties);
        MainTexProp = FindProperty("_MainTex", properties);
        toggleProp = FindProperty("_Toggle", properties);

        //通过materialEditor绘制属性

        isVectorEnbled = material.IsKeywordEnabled("_TOGGLE_ON") ? true : false;
        isVectorEnbled = EditorGUILayout.BeginToggleGroup("开关", isVectorEnbled);

        if (isVectorEnbled)
        {
            material.EnableKeyword("_TOGGLE_ON");
        }
        else
        {
            material.DisableKeyword("_TOGGLE_ON");
        }

        if (isVectorEnbled)
        {
            EditorGUILayout.BeginVertical(new GUIStyle("label"));


            EditorGUILayout.LabelField("浮点数值", new GUIStyle("AM MixerHeader"));
            EditorGUILayout.Space(1);
            materialEditor.FloatProperty(floatProp, "浮点值");
            materialEditor.RangeProperty(rangeProp, "浮点值");
            materialEditor.ColorProperty(colorProp, "基础颜色");
            EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.BeginVertical(new GUIStyle("MinMaxHorizontalSliderThumb"));
        EditorGUILayout.Space(10);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndToggleGroup();

        //materialEditor.VectorProperty(vecotrProp, "四维向量");

        materialEditor.TexturePropertyTwoLines(new GUIContent("纹理"), MainTexProp, colorProp, null, null);
        materialEditor.TexturePropertyWithHDRColor(new GUIContent("纹理"), MainTexProp, colorProp, true);
        materialEditor.TextureScaleOffsetProperty(MainTexProp);
        //EditorGUILayout写法
        VecotrPropX = (int)vecotrProp.vectorValue.x;
        VecotrPropY = vecotrProp.vectorValue.y;
        VecotrPropZ = vecotrProp.vectorValue.z;
        VecotrPropW = vecotrProp.vectorValue.w;

        VecotrPropX = EditorGUILayout.IntField("整数(EditorGUILayout)", VecotrPropX);//把VecotrPropX的值绘制到面板上
        VecotrPropY = EditorGUILayout.Slider("滑杆(EditorGUILayout)", VecotrPropY, -1, 1);
        EditorGUILayout.MinMaxSlider(new GUIContent("滑动条范围"), ref VecotrPropZ, ref VecotrPropW, 0.0f, 10.0f);
        vecotrProp.vectorValue = new Vector4(VecotrPropX, VecotrPropY, VecotrPropZ, VecotrPropW);//实例化一个Vector4 将上述XYZW的值传输到中间变量里


        // base.OnGUI(materialEditor, properties);

    }
}
