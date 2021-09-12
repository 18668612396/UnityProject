Shader "Unlit/AP15"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainSpeed("MainSpeed",Range(-5,5)) = 0
        _NoiseTex01("NoiseTex01",2D) = "white"{}
        _WarpSpeed("WarpSpeed",Range(-5,5)) = 0
        _WarpStrength("WarpStrength",Range(0,1)) = 0
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType"="ForwordBase"

        }
        LOD 100

        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _NoiseTex01;
        float4 _NoiseTex01_ST;
        float _WarpSpeed;
        float _WarpStrength;
        float _MainSpeed;
        ENDCG

        Blend SrcAlpha OneMinusSrcAlpha
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
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv0.y = o.uv0.y  + frac(_Time.x * _MainSpeed);
                o.uv1 = TRANSFORM_TEX(v.uv,_NoiseTex01) ;
                o.uv1.y = o.uv1.y + frac(_Time.x * _WarpSpeed);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 var_NoiseTex01 = tex2D(_NoiseTex01,i.uv1);
                float4 var_MainTex = tex2D(_MainTex,i.uv0 + var_NoiseTex01.rg * _WarpStrength);
                
                // sample the texture
                float4 finalRGB = var_MainTex;

                return finalRGB;
            }
            ENDCG
        }
    }
}
