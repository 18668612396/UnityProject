Shader "Unlit/Built_Parallax"
{
    Properties
    {
        _NormalTex("NormalTex",2D) = "white"{}
        _HeightTex("Height",2D)    = "white"{}
        
        _PomSample("PomSample",int) = 0
        _PomScale("PomScale",Range(0,1)) = 0
        _HeightScale("HeightScale",Range(-1,1)) = 0
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
            #include "../ShaderFunction.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal :NORMAL;
                float3 worldTangent :TANGENT;
                float3 worldBiTangent :TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };
            sampler2D _NormalTex,_HeightTex;
            float _PomScale,_HeightScale;
            int _PomSample;
            float4 _NormalTex_ST;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NormalTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent);
                o.worldBiTangent = cross(o.worldNormal,o.worldTangent) * v.tangent.w;
                o.worldPos    = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 normal = tex2D(_NormalTex, i.uv);
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                float3 tangenWorld_X = float3(i.worldTangent.x,i.worldBiTangent.x,i.worldNormal.x);
                float3 tangenWorld_Y = float3(i.worldTangent.y,i.worldBiTangent.y,i.worldNormal.y);
                float3 tangenWorld_Z = float3(i.worldTangent.z,i.worldBiTangent.z,i.worldNormal.z);
                float3 tangentViewDir = normalize(tangenWorld_X * worldViewDir.x + tangenWorld_Y * worldViewDir.y + tangenWorld_Z * worldViewDir.z);
                
                //float2 uv = POM( _Normal, i.uv.xy, worldNormal, worldViewDir, tangentViewDir, _MinSample, _MaxSample,_SectionSteps, _PomScale * 0.1, _HeightScale,i.vertexColor,_BlendHeight);
                
                return normal;
            }
            ENDCG
        }
    }
}
