Shader "Unlit/AP13_01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("MainColor",Color) = (1,1,1,1)
        _Cutoff("Cutoff",Range(0,1)) = 0
       
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off

        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;
        float _Cutoff;
        float4 _MainColor;
    
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
      

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
  
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 var_MainTex = tex2D(_MainTex,i.uv);
                clip(var_MainTex.a - _Cutoff);
            
                float3 finalRGB = _MainColor;
                return float4(finalRGB,1);
            }
            ENDCG
        }
    }
}
