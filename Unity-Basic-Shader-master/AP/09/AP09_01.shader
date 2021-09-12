Shader "Unlit/AP08_01"
{
    Properties
    {
        
        [KeywordEnum(Phong,BlinnPhong,PhongAddBlinn)] _SpecularMode("SpecularMode",float) = 0
        [Space(20)]
        _AmbientTex("AmbientTex",2D) = "white"{}
        [Normal]_NormalTex("NormalTex",2D) = "bump"{}
        _Albedo("Albedo",Color) = (1.0,1.0,1.0,1.0)
        _SpecularPow("SpecularPow",Range(0.01,1.0)) = 0
        _SpecularStrength("SpecularStrength",Range(0,1)) = 0
        [KeywordEnum(CubeMap,MatCap)]_ReflectionMode("ReflectionMode",float) = 0
        [Cube]_CubeMap("CubeMap",Cube) = "Cube"{}
        _reflectionLOD("reflectionLOD",Range(0,1)) = 0
        _MatCap("MatCap",2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CGINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        // make fog work
        
        #pragma shader_feature _SPECULARMODE_PHONG _SPECULARMODE_BLINNPHONG _SPECULARMODE_PHONGADDBLINN
        #pragma shader_feature _REFLECTIONMODE_CUBEMAP _REFLECTIONMODE_MATCAP
        #pragma shader_feature_fwdbase
        

        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        //贴图采样
        
        sampler2D _AmbientTex;
        sampler2D _NormalTex;
        sampler2D _MatCap;
        samplerCUBE _CubeMap;


        float _SpecularPow;
        float4 _Albedo;
        float _SpecularStrength;
        float _reflectionLOD;
        
        ENDCG

        Pass
        {
            
            CGPROGRAM
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {

                float4 pos : SV_POSITION;
                float3 worldPos :TEXCOORD4;
                float2 uv:TEXCOORD0;
                float3 normal:TEXCOORD1;
                float4 tangent:TEXCOORD2;
                
                LIGHTING_COORDS(5,6)
            };

            

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //贴图采样
                float4 var_AmbientTex = tex2D(_AmbientTex,i.uv);
                float3 var_NormalTex = UnpackNormal(tex2D(_NormalTex,i.uv));
                //投影
                float shadow = LIGHT_ATTENUATION(i);
                
                //TBN
                float3  normalWS = normalize(UnityObjectToWorldNormal(i.normal));
                float4 tangentWS = normalize(mul(unity_ObjectToWorld,float4(i.tangent.xyz,1.0)));
                float3 btangentWS = normalize(cross(normalWS,tangentWS)) * i.tangent.w;
                float3x3 TBN = float3x3(tangentWS.xyz,btangentWS.xyz,normalWS.xyz);
                //准备向量
                float3 normalDir = mul(var_NormalTex,TBN);
                float3 viewDir =normalize( _WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 lightDir =normalize(_WorldSpaceLightPos0.xyz);
                float3 reflectlightDir = reflect(-lightDir,normalDir);
                float3 halfDir = normalize(viewDir + lightDir);

                


                //三色环境光
                
                float4 SkyColor = max(0,normalDir.y) * unity_AmbientSky;
                float4 GroundColor = max(0,-normalDir.y) * unity_AmbientGround;
                float4 EquatorColor = (1-(max(0,-normalDir.y) + max(0,normalDir.y))) * unity_AmbientEquator;
                float4 AmbientColor = (SkyColor + EquatorColor + GroundColor) ;
                
                //光照模型
                float Lambert = max(0,dot(normalDir,lightDir)) ;
                float HalfLmabert = (Lambert * 0.5 + 0.5) *   AmbientColor;
                float Phong = max(0,dot(reflectlightDir,viewDir));
                float BlinnPhong = max(0,dot(normalDir,halfDir));
                
                //MatCap和CubeMap
                //MatCap
                float3 normalVS = normalize(mul(UNITY_MATRIX_V,normalDir));
                float2 MatCapUV = normalVS.xy * 0.5 +0.5;
                float4 var_MatCap = tex2Dlod(_MatCap,half4(MatCapUV,1,_reflectionLOD * 8));

                //_CubeMap
                float3 CubeMapUV = reflect(viewDir,normalDir);
                float4 var_CubeMap = texCUBElod(_CubeMap,half4(CubeMapUV,_reflectionLOD * 8));

                float4 ReflectionColor;
                //切换镜面反射
                #if _REFLECTIONMODE_CUBEMAP
                    ReflectionColor = var_CubeMap;
                #elif _REFLECTIONMODE_MATCAP
                    ReflectionColor = var_MatCap;
                #endif
                //菲尼尔
                float Fresnel = 1-dot(viewDir,normalDir);
                 Fresnel = pow(Fresnel,_reflectionLOD * 8);
                // ReflectionColor = Fresnel * ReflectionColor;
                ReflectionColor =(ReflectionColor +  AmbientColor )* var_AmbientTex;
                
                //切换Phong和BlinnPhong
                float Specular;
                #if _SPECULARMODE_BLINNPHONG
                    Specular = BlinnPhong;
                    
                #elif _SPECULARMODE_PHONG
                    Specular = Phong;
                #elif _SPECULARMODE_PHONGADDBLINN
                    Specular = lerp(Phong,BlinnPhong,0.5);
                #endif
                //
                float4 SpecularColor = pow(Specular,_SpecularPow*100) *_SpecularStrength * _LightColor0;
                
                float4 finalRGB = _Albedo * HalfLmabert * _LightColor0   + SpecularColor  + ReflectionColor;
                return finalRGB;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
