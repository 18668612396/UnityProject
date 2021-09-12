Shader "Unlit/CustomMaterialGUI"
{
    Properties
    {
        [Toggle]_Toggle("Toggle",int) = 0
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _Float ("float0",float) = 0.0
        _Range("Range0",Range(0,1)) = 0.0
        _Vector("Vector0",vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {

            CGINCLUDE
            // make fog work
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            #pragma multi_compile _ _TOGGLE_ON
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Float;
            float _Range;
            float4 _Vector;
            float4 _BaseColor;
            
            ENDCG
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 var_MainTex = tex2D(_MainTex,i.uv);

                float3 finalRGB;
                #ifdef _TOGGLE_ON
                finalRGB = float3(0,0,0);
                #else
                finalRGB = var_MainTex.rgb * _BaseColor * _Vector;
                #endif
                return float4(finalRGB,1);
            }
            ENDCG
        }
    }
 CustomEditor "CustomMaterialGUI"
}
