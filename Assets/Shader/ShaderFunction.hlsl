#ifndef SHADER_FUNCTION_INCLUDE
    #define SHADER_FUNCTION_INCLUDE
    

    float remap(float In ,float InMin ,float InMax ,float OutMin, float OutMax)
    {
        return OutMin + (In - InMin) * (OutMax - OutMin) / (InMax - InMin);
    }


    inline float2 POM( sampler2D heightMap, float2 uvs, float3 normalWorld, float3 viewWorld, float3 viewDirTan, int minSamples, int maxSamples,int sectionSteps, float parallax, float refPlane)
    {
        
        int stepIndex = 0;
        int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, saturate( dot( normalWorld, viewWorld ) ) );
        float layerHeight = 1.0 / numSteps;
        float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
        uvs += refPlane * plane;
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
#endif