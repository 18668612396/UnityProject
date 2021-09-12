Shader "Unlit/AP03_01"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _Ramp("Ramp",2D) = "white"{}
        _Rang("Rang",Range(0,1)) = 0
    }

    CGINCLUDE
    #pragma vertex vert
    #pragma fragment frag
    // make fog work
    #pragma multi_compile_fog

    #include "UnityCG.cginc"
    #include "Lighting.cginc" 
    #include "AutoLight.cginc"

    float4 _Color;
    sampler2D _Ramp;
    float _Rang;

    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            
            struct appdata
            {
                float4 vertex : POSITION;
                
                float3 normal: NORMAL;
            };

            struct vertexOut
            {
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
                float4 vertex : SV_POSITION;
            };

            
            vertexOut vert (appdata i)
            {
                vertexOut o;
                o.vertex = UnityObjectToClipPos(i.vertex);
                o.normal = normalize(UnityObjectToWorldNormal(i.normal));
                
                
                return o;
            }

            fixed4 frag (vertexOut i) : SV_Target
            {
                float3 lightDirWS =normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = max(0,dot(lightDirWS,i.normal));
                float4 RampTex =  tex2D(_Ramp,float2(NdotL,0.5));
                float4 findRGB = lerp(float4(1,1,1,1) * NdotL*0.5+0.5 , RampTex,_Rang);
                
                
                return findRGB;
            }
            ENDCG
        }
    }
}
