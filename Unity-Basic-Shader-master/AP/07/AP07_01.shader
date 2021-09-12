Shader "Unlit/AP07_01"
{
    Properties
    {
        
        [KeywordEnum(Phong,BlinnPhong,PhongAddBlinn)] _SpecularMode("SpecularMode",float) = 0
        [Space(20)]
        _AmbientTex("AmbientTex",2D) = "white"{}
        _Albedo("Albedo",Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",Range(0.01,1.0)) = 0
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
        #pragma multi_compile_fwdbase
        

        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        float _Gloss;
        float4 _Albedo;
        sampler2D _AmbientTex;
        ENDCG

        Pass
        {
            
            CGPROGRAM
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {

                float4 vertex : SV_POSITION;
                float3 worldPos :TEXCOORD1;
                float2 uv:TEXCOORD0;
                float3 normal:NORMAL;
                LIGHTING_COORDS(2,3)
            };

            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //投影
                float shadow = LIGHT_ATTENUATION(i);
                //准备向量
                float3 normalDir = UnityObjectToWorldNormal(i.normal);
                float3 viewDir =normalize( _WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 lightDir =normalize(_WorldSpaceLightPos0.xyz);
                float3 reflectlightDir = reflect(-lightDir,normalDir);
                float3 halfDir = normalize(viewDir + lightDir);

                //三色环境光
                float4 var_AmbientTex = tex2D(_AmbientTex,i.uv);
                float4 SkyColor = max(0,normalDir.y) * unity_AmbientSky;
                float4 GroundColor = max(0,-1 *normalDir.y) * unity_AmbientGround;
                float4 EquatorColor = (1-(max(0,-1 * normalDir.y) + max(0,normalDir.y))) * unity_AmbientEquator;
                float4 AmbientColor = (SkyColor + EquatorColor + GroundColor) * var_AmbientTex;
                
                //光照模型
                float Lambert = max(0,dot(normalDir,lightDir) *0.5 +0.5)  * AmbientColor;
                float Phong = max(0,dot(reflectlightDir,viewDir));
                float BlinnPhong = max(0,dot(normalDir,halfDir));
                
                float Specular ;
                //切换Phong和BlinnPhong
                #if _SPECULARMODE_BLINNPHONG
                    Specular = BlinnPhong;
                    
                #elif _SPECULARMODE_PHONG
                    Specular = Phong;
                #elif _SPECULARMODE_PHONGADDBLINN
                    Specular = lerp(Phong,BlinnPhong,0.5);
                #endif
                //
                float4 SpecularColor = pow(Specular,_Gloss*100) *(_Gloss + 0.2) * _LightColor0;
                
                float4 finalRGB = _Albedo * Lambert * _LightColor0 * shadow + SpecularColor;
                return finalRGB;
            }
            ENDCG
        }
    }
}
