Shader "Unlit/Reflection"
{
    Properties
    {
        _Pos("Pos",vector) = (0,0,0,0)
        _MainTex ("Texture", 2D) = "white" {}
        
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 viewDir :TEXCOORD2;
                float3 worldNormal:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Pos;
            v2f vert (appdata i)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(i.vertex);
                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                o.viewDir = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,i.vertex);
                o.worldNormal = UnityObjectToWorldNormal(i.normal);
                return o;
            }

            fixed3 frag (v2f i) : SV_Target
            {
                //准备向量
                float3 viewDir = normalize(i.viewDir);
                float3 normalDir = normalize(i.worldNormal);
                float3 reflectDir = reflect(-viewDir,normalDir);
                float3 CameraPos = _WorldSpaceCameraPos.xyz;
                //Cube坐标纠正
                reflectDir = reflectDir + _Pos.xyz;
                //采样Cube
                float3 var_Cube = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
                return var_Cube;
            }
            ENDCG
        }
    }
}
