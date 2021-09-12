Shader "Unlit/AP13_02"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("MainColor",Color) = (1,1,1,1)
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendSrc("BlendSrc",int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDst("BlendDst",int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp("BlendOp",int) = 0
        [KeywordEnum(Off,On)]_Zwrite("Zwrite",float) = 0
        
        
    }
    SubShader
    {
        Tags {

            "Queue" = "Transparent"
            "RenderType"="Opaque" 
        }
        LOD 100
        
        
        

        CGINCLUDE

        #pragma vertex vert
        #pragma fragment frag
        // make fog work
        

        #include "UnityCG.cginc"

        sampler2D _MainTex; 
        float4 _MainTex_ST;

        float4 _MainColor;
        
        ENDCG

        Pass
        {
            BlendOp [_BlendOp]
            Blend [_BlendSrc] [_BlendDst]

            ZWrite [_Zwrite]
            
            CGPROGRAM
            
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
                
                
                float4 finalRGB = float4( _MainColor.rgb,var_MainTex.a);
                return finalRGB;
            }
            ENDCG
        }
    }
}
