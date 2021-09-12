Shader "Unlit/AP05_01"
{
    Properties
    {
        
        [KeywordEnum(Phong,BlinnPhong,PhongAddBlinn)] _SpecularMode("SpecularMode",float) = 0
        [Space(20)]
        _Albedo("Albedo",Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CGINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        // make fog work
        #pragma multi_compile_fog
        #pragma shader_feature _SPECULARMODE_PHONG _SPECULARMODE_BLINNPHONG _SPECULARMODE_PHONGADDBLINN

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        float _Gloss;
        float4 _Albedo;
        ENDCG

        Pass
        {
            CGPROGRAM
            
            struct appdata
            {
                float4 vertex : POSITION;
                
                float3 normal:NORMAL;
            };

            struct v2f
            {

                float4 vertex : SV_POSITION;
                float3 worldPos :TEXCOORD1;
                float3 normal:NORMAL;
            };

            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //准备向量
                float3 normalDir = UnityObjectToWorldNormal(i.normal);
                float3 viewDir =normalize( _WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 lightDir =normalize(_WorldSpaceLightPos0.xyz);
                float3 reflectlightDir = reflect(-lightDir,normalDir);
                float3 halfDir = normalize(viewDir + lightDir);
                //光照模型
                float Lambert = max(0,dot(normalDir,lightDir) *0.5 +0.5);
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
                float4 SpacularColor = pow(Specular,_Gloss) * _LightColor0;
                
                

                return _Albedo* Lambert + SpacularColor;
            }
            ENDCG
        }
    }
}
