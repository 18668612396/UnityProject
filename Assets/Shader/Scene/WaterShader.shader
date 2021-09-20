
Shader "Custom/WaterShader"
{
    Properties
    {
        _WrapTile("_WrapTile",Range(-1,500)) = 0.0
        
        _LightFactor("_LightFactor",Range(0.0,1.0)) = 0.0
        _WaterDepth("WaterDepth",float) = 0.0
        [HDR]_WaterTopColor("WaterTopColor",Color) = (1.0,1.0,1.0,1.0)
        _WaterDownColor("WaterDownColor",Color) = (0.0,0.0,0.0,0.0)
        _WaterEdge("WaterEdge",float) = 0.0
        _WaterEdgeTile("_WaterEdgeTile",float) = 1.0
        _WaterEdgeColor("WaterEdgeColor",Color) = (1.0,1.0,1.0,1.0)
        _WaterEdgeWarpTile("WaterEdgeWarpTile",float) = 1.0
        _WaterEdgeWarpIntensity("WaterEdgeWarpIntensity",Range(0.0,5.0)) = 1.0
        [Space(50)]
        _WaterEvnSpecularFactor("_WaterEvnSpecularFactor",float) = 0.0
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
        uniform float _WrapTile;
        uniform float _LightFactor;

        uniform float _WaterDepth;
        uniform float4 _WaterTopColor;
        uniform float4 _WaterDownColor;
        uniform float _WaterEdge;
        uniform float4 _WaterEdgeColor;
        uniform float _WaterEdgeTile;
        uniform float _WaterEdgeWarpTile;
        uniform float _WaterEdgeWarpIntensity;

        uniform float _WaterEvnSpecularFactor;
        ENDCG

        GrabPass
        {
            //此处给出一个抓屏贴图的名称，抓屏的贴图就可以通过这张贴图来获取，而且每一帧不管有多个物体使用了该shader，只会有一个进行抓屏操作
            //如果此处为空，则默认抓屏到_GrabTexture中，但是据说每个用了这个shader的都会进行一次抓屏！
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
                
                //准备向量
                float3 lightDir = normalize(_WorldSpaceLightPos0).xyz;
                float3 normalDir = normalize(i.worldNormal);
                float3 viewDir   =_WorldSpaceCameraPos - i.worldPos;
                float3 reflectDir = reflect(-normalize(viewDir),normalDir);
                float3 warpUV = reflect(viewDir,normalDir);
                float fresnel =1- pow(max(0.0,dot(normalize(viewDir),normalDir)),_WaterEvnSpecularFactor);
                //Warp
                float4 warpTexture;
                warpTexture.x = PerlinNoise(warpUV.xz * _WrapTile + float2(_Time.y,0.0)) * 0.5 + 0.5;
                warpTexture.y = PerlinNoise(warpUV.xz * _WrapTile + float2(-_Time.y,0.0)) * 0.5 + 0.5;
                warpTexture.z = 0.0;
                warpTexture.w = 0.0;
                warpTexture *= 0.1;
                //计算主光源漫反射
                float3 Albedo = tex2Dproj(_GrabTexture,i.scrPos );
                float waterDepthFactor = DEPTH_COMPARE(i,_WaterDepth);
                float3 lightDiffuse = lerp(_WaterDownColor,_WaterTopColor,waterDepthFactor) * Albedo;
                //计算主光源镜面反射
                float EdgeMask =  DEPTH_COMPARE(i,5);
                float waterEdgeRadius = DEPTH_COMPARE(i,_WaterEdge);
                float waterEdgeFactor = (PerlinNoise(i.uv*10) * 0.5 + 0.5) * waterEdgeRadius;
                float waterEdgeWarp = (PerlinNoise(i.uv*_WaterEdgeWarpTile) * 0.5 + 0.5) * _WaterEdgeWarpIntensity;
                float waterEdgeTexture = (PerlinNoise(float2(waterEdgeRadius,0.5) * _WaterEdgeTile + float2(-_Time.y,0.0) + waterEdgeWarp) * 0.5 + 0.5) * waterEdgeFactor;
                float3 lightSpec = waterEdgeTexture * _LightColor0.rgb *(1 - EdgeMask);
                lightSpec = saturate(smoothstep(0.1,0.2,lightSpec));
                //计算主光源贡献
                float3 lightContribution = (lightDiffuse + lightSpec)  * (1 - _LightFactor);

                //计算环境
                //计算环境漫反射
                float3 indirectionDiffuse = 0.0;
                //采样环境反射
                
                float3 var_Cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir + warpTexture.xyx);
                float3 indirectionSpec = var_Cubemap;
                float3 indirectionContribution = indirectionDiffuse + indirectionSpec;
                

                float3 finalRGB = lightContribution + indirectionContribution * _LightFactor;
                BIGWORLD_FOG(i,finalRGB);//大世界雾效
                
                return float4(finalRGB,1 - EdgeMask);
            }
            ENDCG
        }
    }



}
