Shader "Unlit/Terrain"
{
    Properties
    {
        
        _MainTex ("Texture", 2D) = "white" {}
        _Layer01("_Layer01",2D) = "white"{}
        _Layer02("_Layer02",2D) = "white"{}
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float2 layer01_uv :TEXCOORD1;
                float2 layer02_uv :TEXCOORD2;
                float4 worldPos :POSITION1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Layer01;
            float4 _Layer01_ST;
            sampler2D _Layer02;
            float4 _Layer02_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.layer01_uv = TRANSFORM_TEX(v.uv,_Layer01);
                o.layer02_uv = TRANSFORM_TEX(v.uv,_Layer02);
                o.worldPos   = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 var_MainTex = tex2D(_MainTex,i.uv);
                float4 layer01 = tex2D(_Layer01,i.layer01_uv) * var_MainTex.r;
                float4 layer02 = tex2D(_Layer02,i.layer02_uv) * var_MainTex.g;
                
                return (1 - saturate(i.pos.z )) + layer01 + layer02;
            }
            ENDCG
        }
    }
}
