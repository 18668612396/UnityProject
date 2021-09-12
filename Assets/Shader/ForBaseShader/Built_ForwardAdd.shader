
Shader "ForBaseShader/ForwardAdd"
{
	Properties
	{

	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100


		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal :NORMAL;
			};
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 scrPos : TEXCOORD1;
				float3 worldNormal:NORMAL;
			};
			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);//初始化顶点着色器
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 normalDir = normalize(i.worldNormal);

				float atten = 1.0;
				return max(0,dot(normalDir,lightDir)) * atten;
			}
			ENDCG
		}

		// pass
		// {
			// 	Tags
			// 	{
				// 		"LightMode" = "ForwardAdd"
			// 	}

			// 	Blend One One
			// 	CGPROGRAM
			// 	#pragma vertex vert
			// 	#pragma fragment frag

			// 	#pragma multi_compile_fwdadd
			// 	#include "UnityCG.cginc"
			// 	#include "Lighting.cginc"
			// 	#include "AutoLight.cginc"

			// 	struct appdata
			// 	{
				// 		float4 vertex : POSITION;
				// 		float3 normal :NORMAL;
			// 	};
			// 	struct v2f
			// 	{
				// 		float4 vertex : SV_POSITION;
				// 		float4 worldPos : TEXCOORD1;
				// 		float3 worldNormal:NORMAL;
			// 	};

			// 	v2f vert ( appdata v )
			// 	{
				// 		v2f o;
				// 		o.vertex = UnityObjectToClipPos(v.vertex);
				// 		o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				// 		o.worldNormal = UnityObjectToWorldNormal(v.normal);
				// 		return o;
			// 	}

			// 	float4 frag (v2f i):SV_TARGET
			// 	{
				// 		float3 normalDir = normalize(i.worldNormal);
				// 		float3 lightDir  = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);

				// 		fixed3 diffuse = _LightColor0.rgb  * max(0, dot(normalDir, lightDir));

				// 		fixed atten;
				// 		#ifdef USING_DIRECTIONAL_LIGHT  //平行光下不存在光照衰减，恒值为1
				// 			atten = 1.0;
				// 		#else
				// 			#if defined (POINT)    //点光源的光照衰减计算
				// 				//unity_WorldToLight内置矩阵，世界空间到光源空间变换矩阵。与顶点的世界坐标相乘可得到光源空间下的顶点坐标
				// 				float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				// 				//利用Unity内置函数tex2D对Unity内置纹理_LightTexture0进行纹理采样计算光源衰减，获取其衰减纹理，
				// 				//再通过UNITY_ATTEN_CHANNEL得到衰减纹理中衰减值所在的分量，以得到最终的衰减值
				// 				atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				// 			#elif defined (SPOT)   //聚光灯的光照衰减计算
				// 				float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				// 				//(lightCoord.z > 0)：聚光灯的深度值小于等于0时，则光照衰减为0
				// 				//_LightTextureB0：如果该光源使用了cookie，则衰减查找纹理则为_LightTextureB0
				// 				atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				// 			#else
				// 				atten = 1.0;
				// 			#endif
				// 		#endif

				// 		return float4(diffuse * atten,1);
			// 	}
			// 	ENDCG
		// }

	}
}


