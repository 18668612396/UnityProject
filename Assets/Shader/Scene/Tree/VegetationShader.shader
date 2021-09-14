Shader "Custom/VegetationShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TopColor("TopColor",Color) = (1.0,1.0,1.0,1.0)
        _DownColor("DownColor",Color) = (0.0,0.0,0.0,0.0)
        _GradientVector("_GradientVector",vector) = (0.0,1.0,0.0,0.0)
        _CutOff("Cutoff",Range(0.0,1.0)) = 0.0
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE

        uniform sampler2D _MainTex;
        uniform float _CutOff;

        uniform float _TopColor;
        uniform float _DownColor;
        uniform float4 _GradientVector;
        ENDCG
        Pass
        {
            Tags {
                "RenderType"="Opaque"
                "LightMode"="ForwardBase" //这个一定要加，不然阴影会闪烁
                "Queue" = "Geometry"
            } 
            LOD 100
            Cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 localPos:TEXCOORD2;
                LIGHTING_COORDS(98,99)
            };


            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);//初始化顶点着色器
                o.pos = UnityObjectToClipPos(v.vertex);
                o.localPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = v.uv;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float shadow = SHADOW_ATTENUATION(i);
                //采样贴图
                fixed4 var_MainTex = tex2D(_MainTex, i.uv);
                //准备向量
                float4 localPos = i.localPos;
                

                clip(var_MainTex.r - _CutOff);
                return i.localPos.y;
            }
            ENDCG
        }
        pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}	
            Cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f 
            {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.uv = v.texcoord;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
            float4 frag(v2f i ):SV_Target
            {
                
                fixed4 var_MainTex = tex2D(_MainTex, i.uv);
                clip(var_MainTex.r - _CutOff);
                SHADOW_CASTER_FRAGMENT(i)//这个要放到最后一位
            } 
            ENDCG
        }
    }
    CustomEditor "VegetationShaderGUI"
}
