
Shader "ForBaseShader/Water"
{
    Properties
    {
        _Float0("Float 0", Float) = 1
        _MainTex("_MainTex",2D) = "white"{}
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;
        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
            };
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD1;
                float2 uv:TEXCOORD0;
                float4 worldPos:TEXCPPRD2;

            };

            UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );

            uniform float _Float0;

            
            v2f vert ( appdata v )
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.scrPos = ComputeScreenPos(o.vertex );
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }
            
            fixed4 frag (v2f i ) : SV_Target
            {

                fixed4 finalColor;

                float4 screenPos = i.scrPos / i.scrPos.w;

                float screenDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, screenPos.xy ));
                float distanceDepth =1 - saturate(abs((screenDepth - LinearEyeDepth( screenPos.z )) / ( _Float0)));
                float x = cross(distanceDepth,normalize(i.worldPos).y);
                float4 var_MainTex = tex2D(_MainTex,float2(distanceDepth,x ) * _MainTex_ST);
                return var_MainTex;
                return float4(distanceDepth,x,1,1);
            }
            ENDCG
        }
    }



}
