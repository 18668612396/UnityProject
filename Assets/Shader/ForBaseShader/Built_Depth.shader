
Shader "ForBaseShader/BuiltDepth"
{
	Properties
	{
		_Float0("Float 0", Float) = 1

	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		CGINCLUDE

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
			};
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 scrPos : TEXCOORD1;

			};

			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );

			uniform float _Float0;

			
			v2f vert ( appdata v )
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeScreenPos(o.vertex );
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{

				fixed4 finalColor;

				float4 screenPos = i.scrPos / i.scrPos.w;

				float screenDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, screenPos.xy ));
				float distanceDepth =1 - saturate(abs((screenDepth - LinearEyeDepth( screenPos.z )) / ( _Float0)));
				return distanceDepth;
			}
			ENDCG
		}
	}



}
