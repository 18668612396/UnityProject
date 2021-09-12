Shader "Custom/Effect/OverwatchShield"
{
	Properties
	{
		_MainTex("MainTex",2D) = "white"{}
		_Color("Color",Color) = (1.0,1.0,1.0,1.0)
		[Space(10)]
		_PulseIntensity("PulseIntensity",float) = 3.0
		_PulseTimeScale("PulseTimeScale",float) = 2.0
		_PulsePosScale("PulsePosScale",float) = 50.0
		[Space(10)]
		_HexEdgeColor("HexEdgeColor",Color) = (1.0,1.0,1.0,1.0)
		_HexEdgeIntensity("HexEdgeIntensity",float) = 2.0
		_HexEdgeTimeScale("HexEdgeTimeScale",float) = 2.0
		_HexEdgeWidthModifier("HexEdgeWidthModifier",Range(0,1)) = 0.8
		_hexEdgeWidth("_hexEdgeWidth",float) = 1
		_HexEdgePosScale("HexEdgePosScale",float) = 80.0
		[Space(10)]
		_EdgeIntensity("EdgeIntensity",float) = 10.0
		_EdgeExponent("EdgeExponent",float) = 6.0
		_EdgeDepthWidth("EdgeDepthWidth",float) = 1
		

	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
		}
		ZWrite off
		
		HLSLINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		
		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv :TEXCOORD0;
		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv :TEXCOORD0;
			float4 objectPos :TEXCOORD99;
			float4 scrPos:TEXCOORD98;
			float depth :TEXCOORD97;
		};
		sampler2D _MainTex;
		uniform float4 _MainTex_ST;

		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );


		
		uniform float _PulseIntensity;
		uniform float _PulseTimeScale;
		uniform float _PulsePosScale;
		uniform float4 _Color;
		
		uniform float4 _HexEdgeColor;
		uniform float _HexEdgeIntensity;
		uniform float _HexEdgeTimeScale;
		uniform float _HexEdgeWidthModifier;
		uniform float _HexEdgePosScale;
		uniform float _hexEdgeWidth;

		uniform float _EdgeIntensity;
		uniform float _EdgeExponent;
		uniform float _EdgeDepthWidth;

		ENDHLSL
		Pass
		{
			
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			v2f vert (appdata i)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(i.vertex);
				o.objectPos = i.vertex;
				o.uv = i.uv ;
				o.scrPos = ComputeScreenPos(o.pos);
				o.depth = -mul(UNITY_MATRIX_MV,i.vertex).z * _ProjectionParams.w;
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				//采样贴图
				float4 var_MainTex = tex2D(_MainTex,i.uv * _MainTex_ST.xy);
				//蜂窝脉冲
				float horizontalDist = abs(i.objectPos.x);
				float3 PulseTerm = var_MainTex.g * _Color * _PulseIntensity * abs(sin(_Time.y * _PulseTimeScale - horizontalDist * _PulsePosScale + var_MainTex.g));
				//网格脉冲
				float verticalDist = abs(i.objectPos.z);
				float3 hexEdgeTerm = pow(var_MainTex.r,_hexEdgeWidth) * _HexEdgeColor * _HexEdgeIntensity * max(sin((horizontalDist + verticalDist) * _HexEdgePosScale - _Time.y * _HexEdgeTimeScale) - _HexEdgeWidthModifier, 0.0) * (1 / 1 - _HexEdgeWidthModifier);
				//边缘颜色
				float4 screenPos = i.scrPos / i.scrPos.w;

				float screenDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos.xy));
				float distanceDepth =1- saturate(abs((screenDepth - LinearEyeDepth(screenPos.z)) / _EdgeDepthWidth));
				
				float3 edgeTerm = pow(max(var_MainTex.b ,distanceDepth),_EdgeExponent) * _Color * _EdgeIntensity;
				//最终颜色输出
				float3 finalRGB = _Color.rgb + PulseTerm + hexEdgeTerm + edgeTerm;
				float4 finalColor = float4(finalRGB,_Color.a * var_MainTex.a);
				return finalColor;
			}
			ENDHLSL
		}
	}
}
