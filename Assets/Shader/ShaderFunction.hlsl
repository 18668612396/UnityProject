#ifndef SHADER_FUNCTION_INCLUDE
    #define SHADER_FUNCTION_INCLUDE

    
    #include "AutoLight.cginc"
    #include "Lighting.cginc"
    #include "UnityCG.cginc"

    //Noise
    float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
    float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
    float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
    float PerlinNoise( float2 v )
    {
        const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
        float2 i = floor( v + dot( v, C.yy ) );
        float2 x0 = v - i + dot( i, C.xx );
        float2 i1;
        i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
        float4 x12 = x0.xyxy + C.xxzz;
        x12.xy -= i1;
        i = mod2D289( i );
        float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
        float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
        m = m * m;
        m = m * m;
        float3 x = 2.0 * frac( p * C.www ) - 1.0;
        float3 h = abs( x ) - 0.5;
        float3 ox = floor( x + 0.5 );
        float3 a0 = x - ox;
        m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
        float3 g;
        g.x = a0.x * x0.x + h.x * x0.y;
        g.yz = a0.yz * x12.xz + h.yz * x12.yw;
        return 130.0 * dot( m, g );
    }
    //重映射
    float remap(float In ,float InMin ,float InMax ,float OutMin, float OutMax)
    {
        return OutMin + (In - InMin) * (OutMax - OutMin) / (InMax - InMin);
    }

    //风力动画
    uniform int   _WindAnimToggle;
    uniform float  _WindDensity;
    uniform float3 _WindDirection;
    uniform float  _WindSpeedFloat;
    uniform float  _WindTurbulenceFloat;
    uniform float  _WindStrengthFloat;
    void WindAnimation(inout float4 vertex, float4 vertexColor)
    {   
        vertex.xyz = vertex.xyz;
        float3 worldPos = mul(unity_ObjectToWorld,vertex);
        float3 windDirection = float3(_WindDirection.xy,0.0);
        float2 panner = (1.0 * _Time.y * (windDirection * _WindSpeedFloat * 10).xy + worldPos.xy);
        float SimplePerlinNoise = PerlinNoise(panner * _WindTurbulenceFloat / 10 * _WindDensity) * 0.5 + 0.5;
        if(_WindAnimToggle > 0)
        {
            vertex.xyz += mul(unity_WorldToObject,float4(_WindDirection * (SimplePerlinNoise * _WindStrengthFloat),0.0)) * vertexColor.a;
        }
        
        vertex.w = 1.0;
        
    }
    #define WIND_ANIM(v)  WindAnimation(v.vertex,v.color);

    //云阴影
    uniform float _CloudShadowSize;
    uniform vector _CloudShadowRadius;
    uniform float _CloudShadowSpeed;
    uniform float _CloudShadowIntensity;
    float CloudShadow(float3 worldPos)
    {
        
        float Shadow = PerlinNoise(worldPos.xz * _CloudShadowSize * _CloudShadowRadius.xy + _Time.y * _WindDirection * _CloudShadowSpeed);
        
        return lerp(1.0,1.0 - saturate(Shadow),_CloudShadowIntensity);
    }
    #define CLOUD_SHADOW(i)  CloudShadow(i.worldPos);

    //植被交互

    uniform float _InteractRadius;
    uniform float _InteractIntensity;
    uniform float3 _PlayerPos;
    void GrassInteract(float2 uv,float4 vertexColor,inout float4 vertex)
    {
        float3 worldPos = mul(unity_ObjectToWorld,vertex).xyz;
        float interactDistance = distance(_PlayerPos.xyz + float3(0,1.5,0),worldPos);
        float interactDown = saturate((1 - interactDistance + _InteractRadius) * uv.y * _InteractIntensity);
        float3 interactDirection = normalize(worldPos.xyz - _PlayerPos.xyz);
        worldPos.xyz = interactDirection * interactDown * vertexColor.a;
        worldPos.y*= 0.2;
        vertex.xyz += mul(unity_WorldToObject,worldPos);
    }
    #define GRASS_INTERACT(v) GrassInteract(v.uv,v.color,v.vertex);



    //大世界雾效
    //后续编辑脚本GUI时 控制宏开开关
    #pragma multi_compile _WORLDFOG_ON 
    uniform float4 _FogColor;
    uniform float _FogGlobalDensity;
    // uniform float _FogFallOff;
    uniform float _FogHeight;
    uniform float _FogStartDis;
    uniform float _FogInscatteringExp;
    uniform float _FogGradientDis;

    void ExponentialHeightFog(float3 worldPos,inout float3 finalRGB)
    {
       // float heightFallOff = _FogFallOff * 0.01;
        float falloff = 0.01 * ( worldPos.y -  _WorldSpaceCameraPos.y- _FogHeight); //这里节省了 _FogFallOff
        float fogDensity = _FogGlobalDensity * exp2(-falloff);
        float fogFactor = (1 - exp2(-falloff))/falloff;
        float3 viewDir = _WorldSpaceCameraPos - worldPos;
        float rayLength = length(viewDir);
        float distanceFactor = max((rayLength - _FogStartDis)/ _FogGradientDis, 0);
        float fog = fogFactor * fogDensity * distanceFactor;
        float inscatterFactor = pow(saturate(dot(-normalize(viewDir), WorldSpaceLightDir(float4(worldPos,1)))), _FogInscatteringExp);
        inscatterFactor *= 1-saturate(exp2(falloff));
        inscatterFactor *= distanceFactor;
        float3 finalFogColor = lerp(_FogColor, _LightColor0, saturate(inscatterFactor));
        #if _WORLDFOG_ON
        finalRGB =lerp(finalRGB, finalFogColor, saturate(fog));
        #elif _WORLDFOG_OFF
        finalRGB = finalRGB;
        #endif
    }

    #define BIGWORLD_FOG(i,finalRGB) ExponentialHeightFog(i.worldPos,finalRGB);
#endif
