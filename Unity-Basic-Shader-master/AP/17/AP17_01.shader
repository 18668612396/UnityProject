Shader "Unlit/AP17_01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("MainColor",Color) = (1,1,1,1)
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendSrc("BlendSrc",int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDst("BlendDst",int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp("BlendOp",int) = 0
        [KeywordEnum(Off,On)]_Zwrite("Zwrite",float) = 0
        _Noise("Noise",2D) = "white"{}
        _NoiseSpeed("NoiseSpeed",Range(0,1)) = 0
        _WarpStr("WarpStr",Range(0,1)) = 0
        
        
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
        sampler2D _Noise; 
        float4 _Noise_ST;
        float _NoiseSpeed;
        float _WarpStr;
        
        ENDCG
        GrabPass
        {
            "_GrabTex"
        }
        Pass
        {
            
            BlendOp [_BlendOp]
            Blend [_BlendSrc] [_BlendDst]

            ZWrite [_Zwrite]
            
            CGPROGRAM
            uniform sampler2D _GrabTex;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 GrabPos:TEXCOORD1;
                float2 NoiseUV:TEXCOORD2;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.GrabPos = ComputeGrabScreenPos(o.vertex.xyzw);
              
                o.NoiseUV =frac(normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex)) *_Noise_ST.xy + float2(_NoiseSpeed * _Noise_ST.z,_NoiseSpeed * _Noise_ST.w) * _Time.y);

                // o.viewPos = UnityObjectToViewPos(v.vertex);
                // o.viewPos = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex)



                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 var_MainTex = tex2D(_MainTex,i.uv);
                float4 var_Noise = tex2D(_Noise,i.NoiseUV);
                
                float4 finalRGB = float4( _MainColor.rgb,var_MainTex.a);
                float4 var_GrabTex = tex2Dproj(_GrabTex , i.GrabPos + var_Noise *_WarpStr );
                return var_GrabTex ;
            }
            ENDCG
        }
    }
}
