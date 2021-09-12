
Shader "ForBaseShader/BuiltShadow"
{
	Properties
	{

	}
	
	SubShader
	{
		Tags {
			"RenderType"="Opaque"
			"LightMode"="ForwardBase" //这个一定要加，不然阴影会闪烁
			"Queue" = "Geometry"
		} 
		LOD 100

		CGINCLUDE

		ENDCG
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fwdbase
			struct appdata
			{
				float4 vertex : POSITION;
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD1;
				LIGHTING_COORDS(5,6)
			};


			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);//初始化顶点着色器
				o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				float shadow = SHADOW_ATTENUATION(i);
				return shadow;
			}
			ENDCG
		}
		
		pass
		{
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}	

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f 
			{
				V2F_SHADOW_CASTER;
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			float4 frag(v2f i ):SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
				return float4(1,1,1,1);
			} 
			ENDCG
		}
	}
	
}
