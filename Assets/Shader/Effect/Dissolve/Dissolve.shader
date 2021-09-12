Shader "Unlit/Dissolve"
{
    Properties
    {
        _MaxGradient("MaxGradient",float) = 0
        _DissolveSpeed("DissolveSpeed",float) = 1
        _MainTex ("Texture", 2D) = "white" {}
        _Noise ("Noise", 2D) = "white" {}
        [HDR]_FireColor("FireColor",Color) = (0,0,0,0)
        _DissolvePos("DissolvePos",Range(0,1)) = 0
        _BloomRadius ("BloomRadius",Range(0.001,1)) = 0.001
        _DissolveSoftness("DissolveSoftness",Range(0,0.5)) = 0

        _Spread("Spread",Range(0,1)) = 0
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
             
            #include "UnityCG.cginc"
            #include "../../ShaderFunction.hlsl"
 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos :TEXCOORD99;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Noise;
            float4 _Noise_ST;

            float4 _FireColor;

            float _MaxGradient;
            float _DissolvePos;
            float _Spread;
            float _isUseTime;
            float _BloomRadius;
            float _DissolveSpeed;
            float _DissolveSoftness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //采样贴图
                float4 var_MainTex = tex2D(_MainTex,i.uv);
                float var_Noise   = tex2D(_Noise,i.uv * _Noise_ST.xy + _Noise_ST.zw * _Time.y).r; 
                //准备向量
                float MeshPos = mul(unity_ObjectToWorld,float4(0,0,0,1)).y;
                
                //计算渐变
                float Gradient = saturate((i.worldPos.y - MeshPos)/(_MaxGradient + 0.01));

                float  DissolvePos =  remap(frac(_Time.x * _DissolveSpeed),0,1,-_Spread,1) 
                + remap(_DissolvePos,0,1,-_Spread,1);
                
                Gradient = Gradient  - DissolvePos;

                Gradient /= _Spread ;
                
                float Dissolve = Gradient - var_Noise;
                //计算燃烧边缘的MASK
                float BloomMask = saturate(distance(Dissolve,_DissolveSoftness) / _BloomRadius) ;
                //计算燃烧边缘的颜色
                float4 finalColor = lerp(_FireColor,var_MainTex,BloomMask);

                //裁剪
                float AlphaCut = smoothstep(_DissolveSoftness,0.5,Dissolve);
                clip(AlphaCut * var_MainTex.a - 0.5);
                //最终返回
                return finalColor;
            }
            ENDCG
        }
    }
}
