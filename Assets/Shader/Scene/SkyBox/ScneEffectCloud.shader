Shader "SceneEffect/Cloud"
{
    Properties
    {
        _CloudGrow("CloudGrow",Range(-1,1)) = 0
        _CloudPosX("_CloudPosX",Range(0,1)) = 0
        _CloudPosY("_CloudPosY",Range(0,4)) = 0

        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_BaseColor_Light("BaseColor_Light",Color) = (1,1,1,1)
        _lightRadius("_lightRadius",Range(0,10)) = 0
        [HDR]_BaseColor01("_BaseColor01",Color) = (1,1,1,1)
        [HDR]_BaseColor02("_BaseColor02",Color) = (0,0,0,0)
        [HDR]_RimLightColor("_RimLightColor",Color) = (1,1,1,1)


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            Cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos:TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _BaseColor_Light,_BaseColor01,_BaseColor02;
            float4 _ShadowColor;
            float _CutOff;
            float _lightRadius;
            float4 _RimLightColor;

            int _CloudPosX;
            int _CloudPosY;

            float _CloudGrow;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = float2(i.uv.x,i.uv.y) * float2(0.5,0.25) + float2(_CloudPosX,_CloudPosY) * float2(0.5,0.25);

                //采样贴图
                float4 var_MainTex = tex2D(_MainTex, uv);
                // clip(var_MainTex.a - _CutOff);
                //准备向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir  = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                //dot
                float VdotL = max(0,dot(viewDir,-lightDir));

                float LightMask = saturate(pow(VdotL,max(1.0,_lightRadius)));
                _BaseColor01 = _BaseColor01+_BaseColor_Light*LightMask;
                _BaseColor02 = _BaseColor02+_BaseColor_Light*LightMask * 0.2;
                float3 cloudColor = lerp(_BaseColor02,_BaseColor01,var_MainTex.r);
                cloudColor = cloudColor * lerp(1,_RimLightColor,LightMask * var_MainTex.g);
                
                

                float cloudGrow = smoothstep(_CloudGrow,_CloudGrow+0.5,var_MainTex.b);
                return float4(cloudColor,var_MainTex.a * cloudGrow);
            }
            ENDCG
        }
    }
}
