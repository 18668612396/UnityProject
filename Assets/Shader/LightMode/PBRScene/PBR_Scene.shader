Shader "Custom/PBR_Scene"
{
    Properties
    {  
        [Header(Parallax)]

        _MaxSample("MaxSample",int) = 4  //最高采样次数
        _MinSample("MinSample",int) = 4  //最低采样次数
        _SectionSteps("SectionSteps",int) = 4  //视差映射平滑次数
        _PomScale("PomScale",Range(0,1)) = 0   //视差强度
        _HeightScale("HeightScale",Range(-1,1)) = 0 //视差高度  多数用于和别的高度混合


        [Header(BBR Base)]
        _MainTex (" MainTex ", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        [NoScaleOffset]_PbrParam("PbrParamTex",2D) = "white"{}
        _EmissionIntensity("EmissionIntensity",Range(0,10)) = 0
        [PowerSlider(1)]_Metallic ("Metallic",Range(0,1)) = 0
        [PowerSlider(1)]_Roughness("Roughness",Range(0,1)) = 1
        [NoScaleOffset]_Normal(  "Normal" , 2D) = "bump" {}
        [PowerSlider(1)]_NormalIntensity("_NormalIntensity",Range(0,2)) = 1

        [Header(FallDust)]
        _HeightDepth("heightDepth",Range(1.0,20.0)) = 0
        _BlendHeight("BlendHeight",Range(-5,5)) = 0
        _FallDustMainTex("FallDustMainTex",2D) = "white"{}
        _fallDustEmissionIntensity("fallDustEmissionIntensity",Range(0,10)) = 0
        _FallDustColor("FallDustColor",Color) = (1.0,1.0,1.0,1.0)
        _FallDustColorBlend("_FallDustColorBlend",Range(0,1)) = 1
        _FallDustPbrParam("FallDustPbrParam",2D) = "white"{}
        _FallDustMetallic("_FallDustMetallic",Range(0,1)) = 0
        _FallDustRoughness("FallDustRoughness",Range(0,1)) = 1
        _FallDustNormal("FallDustNormal",2D) = "bump"{}
        _FallDustNormalIntensity("FallDustNormalIntensity",Range(0,2)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {
                "RenderType"="Opaque"
                "LightMode"="ForwardBase"
                "Queue" = "Geometry"
            }

            Blend One Zero
            
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON 
            #pragma shader_feature _PARALLAX_ON 
            #pragma shader_feature _FALLDUST_ON
            struct PBR
            {
                float3 baseColor;
                float4 normal;//A通道为高度图
                float3 emission;
                float  roughness;
                float  metallic;
                float  occlusion;
                float  shadow;
                
            };
            #include "PBR_Scene_FallDust.HLSL"
            #include "PBR_Scene_Function.HLSL"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 lightmapUV:TEXCOORD1;
                float4 normal :NORMAL;
                float4 tangent:TANGENT;
                float4 color:COLOR;
                
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 lightmapUV:TEXCOORD1;
                float2 blendUV:TEXCOORD9;
                float4 vertexColor:COLOR;
                float3 worldNormal :TEXCOORD2;
                float3 worldTangent :TEXCOORD3;
                float3 worldBitangent :TEXCOORD4;
                float3 worldView :TEXCOORD5;
                float3 worldPos:TEXCOORD6;
                LIGHTING_COORDS(7,8)
                
            };
            
            //贴图采样器
            uniform sampler2D _MainTex;
            uniform sampler2D _Normal;
            uniform sampler2D _PbrParam;
            uniform float4 _MainTex_ST;
            uniform float4 _BaseColor;
            uniform float _Metallic,_Roughness,_EmissionIntensity;

            float _NormalIntensity;

            uniform int _FallDust;
            uniform int _Parallax;
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);//初始化顶点着色器
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.blendUV = TRANSFORM_TEX(v.uv,_FallDustMainTex);//混合贴图的UV
                #ifndef LIGHTMAP_OFF
                    o.lightmapUV = v.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent).xyz;
                o.worldBitangent = cross(o.worldNormal,o.worldTangent.xyz) * v.tangent.w;
                o.worldView = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex);
                o.vertexColor = v.color;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed3 frag (v2f i) : SV_Target
            {
                //视差映射UV
                #ifndef _FALLDUST_ON
                    i.vertexColor = float4(0.0,0.0,0.0,0.0);
                #endif
                float2 uv = i.uv;
                #ifdef _PARALLAX_ON
                    uv = PBR_PARALLAX(i,_Normal);
                #endif
                //贴图采样
                float4 var_MainTex = tex2D(_MainTex,uv);
                float4 var_PbrParam = tex2D(_PbrParam,uv);
                float4 var_Normal    = tex2D(_Normal,uv);//A通道为高度图
                //PBR
                PBR pbr;
                pbr.baseColor = var_MainTex.rgb * _BaseColor.rgb;
                pbr.emission  = lerp(0,var_MainTex.rgb * max(0.0,_EmissionIntensity),var_PbrParam.a);
                pbr.normal    = lerp(float4(0.5,0.5,1,1),var_Normal,_NormalIntensity);//A通道为高度图
                pbr.metallic  = max(_Metallic,var_PbrParam.r);
                pbr.roughness = _Roughness*var_PbrParam.g;
                //Lightmap相关
                #ifdef LIGHTMAP_ON
                    float3 var_Lightmap = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV.xy));
                    pbr.occlusion = var_PbrParam.b * var_Lightmap.r;
                    pbr.shadow    =  var_Lightmap.g;
                #else
                    pbr.occlusion = var_PbrParam.b;
                    pbr.shadow    =  SHADOW_ATTENUATION(i);
                #endif
                //高度融合相关
                #ifdef _FALLDUST_ON
                    PBR_FALLDUST(i,pbr);
                #endif
                
                float3 finalRGB = PBR_FUNCTION(i,pbr);
                return finalRGB;
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
            }
            ENDCG
        }
    }
    CustomEditor "PBR_ShaderGUI"
}
