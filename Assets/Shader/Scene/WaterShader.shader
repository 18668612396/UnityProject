
Shader "Custom/WaterShader"
{
    Properties
    {
        _WarpScaleOffset("_WarpScaleOffset",vector) = (1.0,1.0,0.0,0.0)
        _WarpIntensity("_WarpIntensity",Range(0.0,1.0)) = 0.5
        _LightFactor("_LightFactor",Range(0.0,1.0)) = 0.0
        _WaterDepth("WaterDepth",float) = 0.0
        [HDR]_WaterTopColor("WaterTopColor",Color) = (1.0,1.0,1.0,1.0)
        _TransparentRadius("_TransparentRadius",Range(0.0,1.0)) = 0.0
        _WaterDownColor("WaterDownColor",Color) = (0.0,0.0,0.0,0.0)
        [Space(50)]
        _WaveRadius("_WaveRadius",Range(0.0,1.0)) = 0.0
        _WaveTile("_WaveTile",float) = 1
        _WaveWidth("_WaveWidth",Range(0.0,0.9)) = 0.0
        _WaveIntensity("_WaveIntensity",Range(0.0,1.0)) = 0.5
        _WaveFactorRadius("_WaveFactorRadius",float) = 0.0
        _WaveFactorIntensity("_WaveFactorIntensity",Range(0.0,1.0)) = 0.0
        [Space(20)]
        _WaveWarpScale("_WaveWarpScale",Range(0.0,1.0)) = 0.0 
        _IndirectionFactor("_IndirectionFactor",float) = 0.0
    }
    
    SubShader
    {
        Tags 
        {
            "RenderType"="Transparent" 
            "Queue" = "Transparent+1"
        }
        LOD 100

        CGINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        #include "../ShaderFunction.hlsl"
        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv:TEXCOORD0;
            float3 normal:NORMAL;
        };
        struct v2f
        {
            float4 vertex : SV_POSITION;
            float4 scrPos : TEXCOORD1;
            float2 uv:TEXCOORD0;
            float4 worldPos:TEXCPPRD2;
            float3 worldNormal:NORMAL;
        };
        uniform float4 _WarpScaleOffset;
        uniform float _WarpIntensity;

        uniform float _LightFactor;

        uniform float _WaterDepth;
        uniform float4 _WaterTopColor;
        uniform float4 _WaterDownColor;
        uniform float _TransparentRadius;

        uniform float _WaveRadius;
        uniform float _WaveTile;
        uniform float _WaveWidth;
        uniform float _WaveIntensity;
        uniform float _WaveFactorIntensity;
        uniform float _WaveFactorRadius;

        uniform float _WaveWarpScale;

        uniform float _IndirectionFactor;
        ENDCG

        GrabPass
        {
            //????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????shader????????????????????????????????????
            //???????????????????????????????????????_GrabTexture????????????????????????????????????shader??????????????????????????????
            "_GrabTexture"
        }
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            sampler2D _GrabTexture;
            v2f vert ( appdata v )
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.scrPos = ComputeScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                return o;
            }
            
            fixed4 frag (v2f i ) : SV_Target
            {
                
                //????????????
                float3 lightDir = normalize(_WorldSpaceLightPos0).xyz;
                float3 normalDir = normalize(i.worldNormal);
                float3 viewDir   =normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 reflectDir = reflect(-viewDir,normalDir);
                float3 cameraPos = _WorldSpaceCameraPos;
                float3 reflectCamera = reflect(cameraPos * 0.5 + i.worldPos,normalDir);

                float fresnel = max(0.0,dot(normalDir,viewDir));
                float indirectionFactor =1 -  pow(fresnel,_IndirectionFactor);
                //????????????
                float2 warp = float2(1.0,1.0);
                warp.x = PerlinNoise(reflectCamera.xz + float2(0.0,_Time.y));
                warp.y = PerlinNoise(reflectCamera.xz + float2(0.0,-_Time.y));
                warp *= _WarpIntensity;
                //????????????????????????
                float3 Albedo = tex2Dproj(_GrabTexture,i.scrPos);
                float DepthFactor = DEPTH_COMPARE(i,_WaterDepth);
                float waterTopFactor = smoothstep(_TransparentRadius,1.0,DepthFactor);
                float3 lightDiffuse = lerp(_WaterDownColor ,lerp(_WaterTopColor,1,waterTopFactor)* Albedo,DepthFactor) ;
                //???????????????????????????
                float waveFactor = distance(cameraPos,i.worldPos);
                waveFactor = 1 - saturate((1 - waveFactor + _WaveFactorRadius) * i.uv.y * _WaveFactorIntensity);
                float waveRadius = smoothstep(_WaveRadius,1,DepthFactor);
                float waveWarp   = PerlinNoise(i.worldPos.xz * _WaveWarpScale);
                float2 waveCoord = float2(0.0,waveRadius) * _WaveTile + float2(0.0,-_Time.y) + waveWarp;
                float3 lightSpec = smoothstep(_WaveWidth,_WaveWidth+0.1,(PerlinNoise(waveCoord) * 0.5 + 0.5) * waveRadius) * _LightColor0.rgb * _WaveIntensity * waveFactor;
                //?????????????????????
                float3 lightContribution = (lightDiffuse + lightSpec)  * (1 - _LightFactor);

                //?????????????????????
                float3 indirectionDiffuse = 0.0;
                //??????????????????
                
                float3 var_Cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir + float3(warp.y,warp.x,0.0));
                float3 indirectionSpec = var_Cubemap;
                float3 indirectionContribution = (indirectionDiffuse + indirectionSpec) * _LightFactor * indirectionFactor;
                

                float3 finalRGB = lightContribution + indirectionContribution;
                BIGWORLD_FOG(i,finalRGB);//???????????????
                
                float Alpha =1 - smoothstep(0.9,1,DepthFactor);
                return float4(finalRGB,Alpha);
            }
            ENDCG
        }
    }



}
