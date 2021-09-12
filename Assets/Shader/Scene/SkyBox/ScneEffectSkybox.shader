Shader "SceneEffect/Skybox"
{
    Properties
    {
        [HDR]_NightSkyColDelta("天空高处颜色", Color) = (0.6, 0.75, 0.82, 0.4)
        [HDR]_NightSkyColBase("天空低处颜色", Color) = (0, 0.7, 1, 1)
        [PowerSlider(1)]_SmoothStepSkyUp("控制天空高处颜色范围", Range(0.0, 1.0)) = 0.5
        [PowerSlider(1)]_SmoothStepSkyDown("控制天空低处颜色范围", Range(0.0, 1.0)) = 0.4
        _SunHaloRadius("SunHaloRadius",Range(0,10)) = 0
        [HDR]_SunHaloColor("SunHaloColor",Color) = (1,1,1,1)
        [Toggle]_DistantViewToggle("显示远景山",Float ) = 1.0
        _DistantViewMap("远景山贴图", 2D) = "white" {}
        [HDR]_DistantViewLightTint("远景山光照颜色",Color) = (1,1,1,0.0)
        _DistantViewTint("远景山基础颜色",Color) = (1,1,1,0.0)
        _DistantFogTint ("远景山雾效颜色",Color) = (1.0,1.0,1.0,1.0)
        _SmoothStepUp("山以上部分雾效", Range(0.0, 1.0)) = 0.5
        _SmoothStepDown("山以下部分雾效", Range(0.0, 1.0)) = 0.4

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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos:TEXCOORD1;
                float3 worldNormal:NORMAL;
                float2 uv2 :TEXCOORD2;
            };
            //天空参数
            float4 _NightSkyColDelta;
            float4 _NightSkyColBase;
            float  _SmoothStepSkyUp;
            float  _SmoothStepSkyDown;
            float4 _SunHaloColor;
            float _SunHaloRadius;

            int _DistantViewToggle;
            sampler2D _DistantViewMap;
            float4 _DistantViewMap_ST;

            float4 _DistantViewLightTint;
            float4 _DistantViewTint;
            float4 _DistantFogTint;
            float  _SmoothStepUp;
            float  _SmoothStepDown;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = TRANSFORM_TEX(v.uv,_DistantViewMap);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed3 frag (v2f i) : SV_Target
            {  
                //准备向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir  = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 normalDir= normalize(i.worldNormal);


                //dot
                float NdotL = max(0.0,dot(normalDir,-lightDir)) * 0.5 + 0.5;

                //采样贴图
                half4 var_DistantViewMap = tex2D(_DistantViewMap, i.uv2);

                //太阳光晕照射
                float SunHaloRadius = pow(NdotL,_SunHaloRadius);
                float3 SunHalo = _SunHaloColor * SunHaloRadius;
                //天空颜色
                float3 skyBoxBaseColor = lerp(_NightSkyColBase,_NightSkyColDelta,smoothstep(_SmoothStepSkyDown,_SmoothStepSkyUp,i.uv.y)).rgb;
                skyBoxBaseColor = lerp(skyBoxBaseColor,SunHalo,SunHaloRadius);
                
                //远景山
                float3 distantLight  =  lerp(_DistantViewTint,_DistantViewLightTint,SunHaloRadius);
                float3 distantAlbedo = var_DistantViewMap * distantLight;
                //远景山雾效
                float  distantFogRadius  = smoothstep(_SmoothStepDown, _SmoothStepUp, i.uv.y);
                float3 distantFogColor    = lerp(_DistantFogTint,_DistantFogTint * var_DistantViewMap.g,distantFogRadius) ;
                float3 distantColor = lerp(distantFogColor,distantAlbedo,distantFogRadius);

                float3 finalRGB;
                if (_DistantViewToggle > 0)
                {
                    finalRGB = lerp(skyBoxBaseColor,distantColor,var_DistantViewMap.a);
                }
                else
                {
                    finalRGB = skyBoxBaseColor;
                }
                
                
                return finalRGB;
            }
            ENDCG
        }
    }
}

