#ifndef PBR_FUNCTION_INCLUDE
    #define PBR_FUNCTION_INCLUDE


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
        float3 reflectDir = normalize(reflect(-viewDir,normalDir));
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
#endif