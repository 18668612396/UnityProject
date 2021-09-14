
Shader "ForBaseShader/Water"
{
    Properties
    {
        _WaveRadius("WaveRadius 0", Range(0.0,10.0)) = 1
        _MainTex("_MainTex",2D) = "white"{}
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;

        uniform float _WaveRadius;
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
                float distanceDepth = 1 - saturate(abs((screenDepth - LinearEyeDepth( screenPos.z )) * ( _WaveRadius)));
                float x = sin(cross(i.worldPos.x,distanceDepth));
                float4 var_MainTex = tex2D(_MainTex,float2(distanceDepth,i.worldPos.x) * _MainTex_ST + float2(-_Time.x,0)) * distanceDepth;
                
                return distanceDepth;
            }
            ENDCG
        }
    }



}
