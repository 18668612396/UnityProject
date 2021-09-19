
Shader "Custom/WaterShader"
{
    Properties
    {
        _MainTex("_MainTex",2D) = "white"{}
        [HDR]_Color("Color",Color) = (1.0,1.0,1.0,1.0)
        _Color02("color02",Range(0.0,1.0)) = 0.5
        _WaveRadius("WaveRadius", Range(0.0,10.0)) = 1
        
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
        uniform sampler2D _MainTex;
        uniform float4 _MainTex_ST;
        uniform float4 _Color;
        uniform float _Color02;
        ENDCG

        // GrabPass
        // {
        //     //此处给出一个抓屏贴图的名称，抓屏的贴图就可以通过这张贴图来获取，而且每一帧不管有多个物体使用了该shader，只会有一个进行抓屏操作
        //     //如果此处为空，则默认抓屏到_GrabTexture中，但是据说每个用了这个shader的都会进行一次抓屏！
        //     "_GrabTexture"
        // }
        Pass
        {
            CGPROGRAM
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
            
            sampler2D _GrabTexture;
            float4 _GrabTexture_ST;
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
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 normalDir = i.worldNormal;
                float3 viewDir   = _WorldSpaceCameraPos - i.worldPos;
                float3 reflectDir = reflect(-viewDir,normalDir);
                //采样GrabTexture
                float  var_Noise = PerlinNoise(i.uv * 50 + _Time.y);
                float3 var_GrabTexture = tex2Dproj(_GrabTexture,i.scrPos + var_Noise * 0.05);

                //采样环境反射
                float3 var_Cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
                fixed4 finalColor;
                float distanceDepth = DEPTH_COMPARE(i);
                float3 finalRGB = lerp(_Color*_Color02,_Color,distanceDepth);
                
                return distanceDepth ;
            }
            ENDCG
        }
    }



}
