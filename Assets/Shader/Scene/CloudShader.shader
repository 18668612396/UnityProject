Shader "SceneEffect/CloudShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1.0,1.0,1.0,1.0)
        _CloudAminSpeed("CloudAminSpeed",Range(0.0,0.5)) = 0.5
        _RimpIntensity("RimpIntensity",Range(0.0,2)) = 0.0
        _MaxLightRadius("_MaxLightRadius",float) = 0.0
        _MinLightRadius("_MinLightRadius",float) = 80
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "LightMode"="ForwardBase" //这个一定要加，不然阴影会闪烁
            "Queue" = "Transparent"
        } 
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            Cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "../ShaderFunction.hlsl"     
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos:TEXCOORD1;
                float3 worldNormal:NORMAL;
                float3 randomFloat:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CloudAminSpeed;
            float4 _Color;
            uniform float _test;
            float _RimpIntensity;
            float _MaxLightRadius;
            float _MinLightRadius;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPivot = mul(unity_ObjectToWorld,float4(0.0,0.0,0.0,1.0));
                float  randomfloat = abs(worldPivot.x + worldPivot.y + worldPivot.z) * 0.01;
                o.randomFloat =abs((frac((_Time.x +randomfloat) * _CloudAminSpeed) - 0.5) * 3) - 0.5;
                // o.randomFloat = mul(unity_WorldToObject,o.randomFloat.xxx);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {


                //采样贴图
                float4 var_MainTex = tex2D(_MainTex, i.uv);
                // clip(var_MainTex.a - _CutOff);
                //准备向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir  = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 normalDir = normalize(i.worldNormal);
                //dot
                float VdotL = max(0,dot(viewDir,-lightDir)) * 0.5 + 0.5;
                //太阳光照范围
                float lightMaxRadiusFactor = pow(VdotL,_MaxLightRadius);
                float lightMinRadiusFactor = pow(VdotL,_MinLightRadius);
                //Cloud动画
                float aminRandomTime = i.randomFloat;

                float cloudAlphaFactor = smoothstep(aminRandomTime,aminRandomTime + 0.5,var_MainTex.b);
                //基础颜色
                float3 Albedo = _Color.rgb;
                float Occlustion = 1;
                //边缘光
                float rimpLight = lerp(1.0,_RimpIntensity,var_MainTex.g * cloudAlphaFactor * lightMaxRadiusFactor);
                //主光源影响
                float shadow = var_MainTex.r;
                float translucidus = lerp(lightMaxRadiusFactor,lightMinRadiusFactor,abs(lightDir));
                float3 lightContribution =  Albedo * _LightColor0.rgb * (shadow + translucidus) * rimpLight;
                //环境光源影响
                float3 Ambient = ShadeSH9(float4(normalDir,1));
                float3 indirectionContribution = Ambient * Albedo * Occlustion * rimpLight;
                //最终颜色
                float3 finalRGB = lightContribution + indirectionContribution;

                return float4(finalRGB,(var_MainTex.a) * cloudAlphaFactor);
            }
            ENDCG
        }
    }
}
