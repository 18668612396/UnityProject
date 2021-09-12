#ifndef PBR_FUNCTION_INCLUDE
    #define PBR_FUNCTION_INCLUDE
    
    

    //PBR代码
    uniform samplerCUBE _cube;
    //D项 法线微表面分布函数
    float D_Function (float NdotH,float roughness)
    {
        float a      = roughness*roughness;
        float a2     = a*a;
        float NdotH2 = NdotH*NdotH;
        float nom   = a2;
        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
        denom = UNITY_PI * denom * denom;
        return nom / denom;
    }

    //G项 几何函数
    float G_SubFunction(float NdotW , float K)
    {
        return NdotW / lerp(NdotW,1.0,K);
    }
    float G_Function (float NdotL,float NdotV,float roughness)
    {
        float K = (1.0+roughness) * (1.0+roughness) / 8;
        return G_SubFunction(NdotL,K) * G_SubFunction(NdotV,K);
    }

    //直接光F项
    float3 F_Light_Function (float HdotL, float3 F0)
    {
        float fresnel = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
        return lerp(fresnel,1.0,F0);
    }
    //间接光F项
    float3 F_Indir_Function(float NdotV,float roughness,float3 F0)
    {
        float fresnel = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
        return F0 + fresnel * saturate(1 - roughness - F0);
    }
    //直接光镜面反射 
    float3 DGF_Function(float NdotH,float NdotL,float NdotV,float HdotL,float roughness,float shadow,float3 F0)
    {
        float  D = D_Function(NdotH,roughness);
        float  G = G_Function(NdotL,NdotV,roughness);
        float3 F = F_Light_Function(HdotL,F0);
        float3 light_BRDF = saturate(( D * G * F ) / (4 * NdotL * NdotV + 0.001));//这里我自行修改了一下 把他限制在0-1

        return light_BRDF * _LightColor0.rgb * NdotL * UNITY_PI * shadow;
    }
    //直接光照漫反射
    float3 lightDiffuse_Function(float HdotL,float NdotL , float3 baseColor,float metallic,float shadow,float3 F0)
    {
        float3 KS = F_Light_Function(HdotL,F0);
        float3 KD = (1 - KS) * (1 - metallic);
        return KD * baseColor * _LightColor0.rgb * NdotL * shadow; 
    }

    

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////间接光部分
    //LUT拟合曲线
    float2 LUT_Approx(float roughness, float NoV )
    {
        // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
        // Adaptation to fit our G term.
        const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
        const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
        float4 r = roughness * c0 + c1;
        float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
        float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;
        return saturate(AB);
    }
    //间接光漫反射
    float3 indirectionDiffuse_Function(float NdotV,float3 normalDir,float metallic,float3 baseColor,float roughness,float occlusion,float3 F0)
    {
        float3 SHColor = ShadeSH9(float4(normalDir,1));
        float3 KS = F_Indir_Function(NdotV,roughness,F0);
        float3 KD = (1 - KS) * (1 - metallic);
        return SHColor * KD * baseColor * occlusion;//这里可以乘以一个AO
    }

    //间接光镜面反射
    float3 indirectionSpec_Function(float3 reflectDir,float roughness,float NdotV,float occlusion,float3 F0)
    {
        //采样环境贴图
        float mip = roughness * (1.7 - 0.7 * roughness) * UNITY_SPECCUBE_LOD_STEPS ;
        float3 indirectionCube = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, mip);
        indirectionCube = DecodeHDR(float4(indirectionCube,1), unity_SpecCube0_HDR);
        
        //拟合曲线
        float2 LUT = LUT_Approx(roughness,NdotV);
        float3 F_IndirectionLight = F_Indir_Function(NdotV,roughness,F0);//环境菲尼尔
        float3 indirectionSpecFactor = indirectionCube.rgb  * (F_IndirectionLight * LUT.r + LUT.g);
        return indirectionSpecFactor * occlusion;
    }
    
    //计算直接光照的贡献
    float3 lightContribution(float NdotH,float NdotL,float NdotV,float HdotL,float roughness,float3 baseColor,float metallic,float shadow,float3 F0)
    {
        return lightDiffuse_Function(HdotL,NdotL,baseColor,metallic,shadow,F0) + DGF_Function(NdotH,NdotL,NdotV,HdotL,roughness,shadow,F0);
    }
    
    //计算环境光照的贡献
    float3 indirectionContribution(float3 reflectDir,float3 normalDir,float NdotV,float3 baseColor,float roughness,float metallic,float occlusion,float3 F0)
    {
        float3 indirectionDiffuse = indirectionDiffuse_Function(NdotV,normalDir,metallic,baseColor,roughness,occlusion,F0);
        float3 indirectionSpec    = indirectionSpec_Function(reflectDir,roughness,NdotV,occlusion,F0);
        return indirectionDiffuse + indirectionSpec;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //计算自发光
    float3 emission_Function(float3 emission)
    {
        return emission;
    }

    
    
    float3 PBR_Function (float3 worldTangent,float3 worldBitangent,float3 worldNormal,float3 worldView,float3 worldPos,PBR pbr)
    {
        
        //参数输入
        float3 baseColor = pbr.baseColor;
        float3 normal    = pbr.normal.xyz;
        float  roughness = pbr.roughness;
        float  metallic  = pbr.metallic;
        float3  emission  = pbr.emission;
        float  occlusion = pbr.occlusion;
        float  shadow    = pbr.shadow;
        float3 F0 = lerp(0.04,baseColor,metallic);
        //法线计算
        float3x3 TBN = float3x3(normalize(worldTangent),normalize(worldBitangent),normalize(worldNormal));
        //向量准备
        float3 normalDir  = mul(pbr.normal * 2 - 1,TBN);//映射法线  *2-1的操作在这里执行
        float3 viewDir    = normalize(worldView);
        float3 lightDir   = normalize(_WorldSpaceLightPos0.xyz);
        float3 halfDir    = normalize(lightDir + viewDir);
        float3 reflectDir = normalize(reflect(viewDir,normalDir));
        //点乘结果
        float NdotH = max(0.00001,dot(normalDir,halfDir));
        float NdotL = max(0.00001,dot(normalDir,lightDir));
        float NdotV = max(0.00001,dot(normalDir,viewDir));
        float HdotL = max(0.00001,dot(halfDir,lightDir));
        
        float3 lighting = lightContribution(NdotH,NdotL,NdotV,HdotL,roughness,baseColor,metallic,shadow,F0);
        float3 indirection = indirectionContribution(reflectDir,normalDir,NdotV,baseColor,roughness,metallic,occlusion,F0);
        float3 emissionLight = emission_Function(emission);

        return lighting +  indirection + emissionLight;
    }

    #define PBR_FUNCTION(i,pbr) PBR_Function(i.worldTangent,i.worldBitangent,i.worldNormal,i.worldView,i.worldPos,pbr);
    

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //补充项

    //视差映射UV计算
    inline float2 POM( sampler2D heightMap, float2 uvs, float3 normalWorld, float3 viewWorld, float3 viewDirTan, int minSamples, int maxSamples,int sectionSteps, float parallax, float refPlane,float vertexColor,float _BlendHeight)
    {
        int stepIndex = 0;
        int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, saturate( dot( normalWorld, viewWorld ) ) );
        float layerHeight = 1.0 / numSteps;
        float2 plane = parallax  * ( viewDirTan.xy / viewDirTan.z );
        uvs += lerp(refPlane,_BlendHeight,vertexColor.r) * plane;//这里增加了顶点色影响 后面要看有没有问题
        float2 deltaTex = -plane * layerHeight;
        float2 prevTexOffset = 0;
        float prevRayZ = 1.0f;
        float prevHeight = 0.0f;
        float2 currTexOffset = deltaTex;
        float currRayZ = 1.0f - layerHeight;
        float currHeight = 0.0f;
        float intersection = 0;
        float2 finalTexOffset = 0;
        float2 dx = ddx(uvs);
        float2 dy = ddy(uvs);
        while ( stepIndex < numSteps + 1 )
        {
            currHeight = tex2D( heightMap, uvs + currTexOffset, dx, dy ).a;
            currHeight = lerp(currHeight,1.0,vertexColor);
            if ( currHeight > currRayZ )
            {
                stepIndex = numSteps + 1;
            }
            else
            {
                stepIndex++;
                prevTexOffset = currTexOffset;
                prevRayZ = currRayZ;
                prevHeight = currHeight;
                currTexOffset += deltaTex;
                currRayZ -= layerHeight;
            }
        }
        int sectionIndex = 0;
        float newZ = 0;
        float newHeight = 0;
        while ( sectionIndex < sectionSteps )
        {
            intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ );
            finalTexOffset = prevTexOffset + intersection * deltaTex;
            newZ = prevRayZ - intersection * layerHeight;
            newHeight = tex2D( heightMap, uvs + finalTexOffset, dx, dy ).a;
            newHeight = lerp(newHeight,1.0,vertexColor);
            if ( newHeight > newZ )
            {
                currTexOffset = finalTexOffset;
                currHeight = newHeight;
                currRayZ = newZ;
                deltaTex = intersection * deltaTex;
                layerHeight = intersection * layerHeight;
            }
            else
            {
                prevTexOffset = finalTexOffset;
                prevHeight = newHeight;
                prevRayZ = newZ;
                deltaTex = ( 1 - intersection ) * deltaTex;
                layerHeight = ( 1 - intersection ) * layerHeight;
            }
            sectionIndex++;
        }
        return uvs + finalTexOffset;
    }

    uniform int _SectionSteps,_MinSample,_MaxSample;
    uniform float _PomScale,_HeightScale;
    uniform float _BlendHeight;
    //视差映射计算
    float2 Parallax (float4 vertexColor,float3 worldTangent,float3 worldBitangent, float3 worldNormal,float3 worldPos,float2 uv,sampler2D _Normal)//这里是用的法线的A通道来作为高度
    {
        
        worldNormal = normalize(worldNormal);
        float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

        float3 tangenWorld_X = float3(worldTangent.x,worldBitangent.x,worldNormal.x);
        float3 tangenWorld_Y = float3(worldTangent.y,worldBitangent.y,worldNormal.y);
        float3 tangenWorld_Z = float3(worldTangent.z,worldBitangent.z,worldNormal.z);
        float3 tangentViewDir = normalize(tangenWorld_X * worldViewDir.x + tangenWorld_Y * worldViewDir.y + tangenWorld_Z * worldViewDir.z);
        
        uv = POM(_Normal, uv, worldNormal, worldViewDir, tangentViewDir, _MinSample, _MaxSample,_SectionSteps, _PomScale * 0.1, _HeightScale,vertexColor,_BlendHeight);
        return uv;
    }
    #define PBR_PARALLAX(i,_Normal)  Parallax(i.vertexColor,i.worldTangent,i.worldBitangent,i.worldNormal,i.worldPos,i.uv,_Normal)

#endif

