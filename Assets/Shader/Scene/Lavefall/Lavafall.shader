Shader "Unlit/Lavafall"
{
    Properties
    {
        _MainTex ("主贴图", 2D) = "white" {}
        _LavaStrength("岩浆发光强度",Range(1,5)) = 1
        _LavaWarpStrength("熔岩扭曲强度",Range(0,1)) = 0
        [Space(20)]
        _NoiseScaleAndSpeed("岩浆扭曲大小及速度",Vector) = (1,1,0,0)
        _NoiseDir("岩浆扭曲的方向(顶点动画的方向)",Vector) = (0,0,0,0)
        _VertexColorRange("岩浆高亮部分的范围(顶点色范围)",Range(-1,1)) = 0
        [HDR]_LavaHighColor("岩浆高亮部分的颜色",Color) = (1,1,1,1)
        _NoisePow("岩浆高亮部分的强度",float) = 0

        _RockColor("岩浆黑色部分",Color) = (0,0,0,0)
    }
    SubShader
    {
        
        Tags { "RenderType"="Opaque" }
        LOD 100
        ZWrite on

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color :COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos:TEXCOORD1;
                float4 color :COLOR;
                float4 noise:TEXCOORD2;
            };
            //noise计算
            float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
            float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
            float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
            float snoise( float2 v )
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
            //Noise计算END
            sampler2D _MainTex;
            float4 _MainTex_ST;
            


            float4 _LavaHighColor;
            float _LavaStrength;
            float4 _NoiseScaleAndSpeed;
            float4 _NoiseDir;
            float _VertexColorRange;
            float _NoisePow;
            float _LavaWarpStrength;

            float4 _RockColor;
            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;
                o.noise = saturate(snoise(v.uv  * _NoiseScaleAndSpeed.xy + _Time.y * _NoiseScaleAndSpeed.zw));
                
                v.vertex = v.vertex + _NoiseDir* (o.noise*2-1) * (1 - v.color.g);
                o.vertex = UnityObjectToClipPos(v.vertex) ;
                o.color = v.color;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float noise = i.noise;
                fixed4 var_MainTex = tex2D(_MainTex, (i.uv * _MainTex_ST.xy + frac(_Time.y * _MainTex_ST.zw)) + i.noise.r * _LavaWarpStrength) * _LavaStrength;
                var_MainTex.a = pow(var_MainTex.a,_NoisePow);
                float4 vertexColor = i.color;
                float highMask = saturate(i.color.r + _VertexColorRange - i.noise.r - var_MainTex.a);
                float4 finalRGB = lerp (var_MainTex,_LavaHighColor,highMask);

                
                return finalRGB;
            }
            ENDCG
        }
    }
}
