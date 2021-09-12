Shader "Unlit/AP12"
{
    Properties
    {
        [NoScaleOffset] _MainTex("MainTex",2D) = "white"{}
        [NoScaleOffset] _NormalTex("NormalTex",2D) = "Bump"{}
        [NoScaleOffset] _AmbientTex    ("AoTex",2D) = "White"{} 
        [NoScaleOffset] _CubeMap  ("CubeMap",Cube) = "Cube"
        [NoScaleOffset] _MatCap   ("MatCap",2D) = "White"{}
        _BaseColor("BaseColor",Color) = (1.0,1.0,1.0,1.0)
        [KeywordEnum(Phong,BlinnPhong)] _SpecularMode("SpecularMode",float) = 0
        _SpecularPow("SpecularPow",Range(1,80)) = 1
        _SpecularStrength("_SpecularStrength",Range(0,1)) = 0
        [KeywordEnum(CubeMap,MatCap)] _ReflectionMode("ReflectionMode",float) = 0
        _ReflectionColor("ReflectionColor",Color) = (1.0,1.0,1.0,1.0)
        _ReflectionMip("ReflectionMip",Range(0,8)) = 0
        _EnvironmentStrength("EnvironmentStrength",Range(0,1)) = 0
        _FresnelPow("FresnelPow",Range(0,10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CGINCLUDE
        //着色器入口
        #pragma vertex vert
        #pragma fragment frag
        //库调用
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        //变量声明
        //----------------------------------------
        
        //贴图采样
        uniform sampler2D _MainTex;
        uniform sampler2D _NormalTex;
        uniform sampler2D _AmbientTex;
        uniform sampler2D _MatCap;
        uniform samplerCUBE _CubeMap;
        //----------------------------
        uniform float4 _BaseColor;
        //-----------------------------
        uniform float _SpecularPow;
        uniform float _SpecularStrength;
        //-----------------------------
        uniform float4 _ReflectionColor;
        uniform float _ReflectionMip;
        uniform float _FresnelPow;
        uniform float _EnvironmentStrength;

        //变体声明
        #pragma multi_compile_fog
        #pragma multi_compile_fwdbase
        #pragma shader_feature _SPECULARMODE_PHONG _SPECULARMODE_BLINNPHONG
        #pragma shader_feature _REFLECTIONMODE_CUBEMAP _REFLECTIONMODE_MATCAP
        ENDCG
        Pass
        {
            CGPROGRAM
            
            // make fog work
            



            struct appdata
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS:NORMAL;
                float4 tangentOS:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 posWS :TEXCOORD2;
                float3 normalOS:NORMAL;
                float4 tangentOS:TANGENT;
                SHADOW_COORDS(3)
            };


            v2f vert (appdata i)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(i.posOS);
                o.posWS = mul(unity_ObjectToWorld,i.posOS);
                o.uv = i.uv;
                o.normalOS = i.normalOS;
                o.tangentOS = i.tangentOS;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed3 frag (v2f i) : SV_Target
            {
                //阴影
                float Shadow = LIGHT_ATTENUATION(i);//声明阴影
                //采样贴图
                float3 var_MainTex = tex2D(_MainTex,i.uv);
                float3 var_NormalTex = UnpackNormal(tex2D(_NormalTex,i.uv));//采样并解包法线贴图
                float3 var_AmbientTex = tex2D(_AmbientTex,i.uv);
                //准备向量
                float3 posWS = i.posWS;//世界空间顶点坐标
                float3 normalWS = normalize(UnityObjectToWorldNormal(i.normalOS));//世界空间法线坐标
                float3 tangentWS = UnityObjectToWorldDir(i.tangentOS);//世界空间切线向量
                float3 btangentWS = normalize(cross(tangentWS,normalWS) );//世界空间副切线向量,DX
                float3x3 TBN = float3x3(tangentWS.xyz,btangentWS.xyz,normalWS.xyz);//BNT矩阵
                normalWS = mul(var_NormalTex,TBN);//将法线贴图通过TBN矩阵转换
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - posWS);//世界空间视向量
                float3 normalVS = normalize(mul(UNITY_MATRIX_V,normalWS));//视空间法线向量，用于MatCap的UV采样
                float3 lightDir = normalize(_WorldSpaceLightPos0).xyz;//主光源向量
                float3 rlightDir = reflect( -lightDir,normalWS);//主光源的反射向量，用于计算Phong的高光
                float3 halfAngle = normalize(lightDir + viewDirWS);//计算半角向量
                float4 CubeMapUV = float4(reflect(-viewDirWS,normalWS),_ReflectionMip);//计算CubeMap的UV (视角的反射方向)并使用了Mipmap
                float4 MatCapUV = float4(normalVS.xy * 0.5 + 0.5,0,_ReflectionMip);//计算MatCap的UV (视空间的法线方向)并使用了Mipmap
                float Fresnel = pow(1 - dot(viewDirWS,normalWS),_FresnelPow);
                
                
                //光照模型
                float Lambert = dot(lightDir,normalWS);//兰伯特光照计算
                float HalfLmabert = Lambert * 0.5 + 0.5;//半兰伯特光照计算
                float Phong = max(0,dot(rlightDir , viewDirWS));//Phong光照计算
                float BlinnPhong = max(0,dot(normalWS,halfAngle));//BlinnPhong光照计算
                //切换高光模式
                float Specular;//声明高光变量
                #if _SPECULARMODE_PHONG //如果PHONG宏生效
                    Specular = Phong;//高光为Phong
                #elif _SPECULARMODE_BLINNPHONG//如果BLINNPHONG宏生效
                    Specular = BlinnPhong;//高光为BlinnPhong
                #endif//if结束
                Specular = pow(Specular,_SpecularPow) * _SpecularStrength;//计算高光POW和强度
                


                //环境光
                float3 SkyColor = unity_AmbientSky.rgb;//获取系统环境光顶部颜色
                float3 EquatorColor = unity_AmbientEquator.rgb;//获取系统环境光中间颜色
                float3 GroundColor = unity_AmbientGround.rgb;//获取系统环境光底部颜色
                SkyColor *= max(0,normalWS.y);//利用法线的Y方向给顶部赋值（因为有负数，所以要提前MAX掉）
                EquatorColor *= 1- (max(0,-normalWS.y) + max(0,normalWS.y));//利用(1-(y+-y))给侧边赋值（因为有负数，所以要提前MAX掉）
                GroundColor *= max(0,-normalWS.y);//利用-Y方向给底部赋值
                float3 AmbinetColor = SkyColor + EquatorColor + GroundColor;//将三个环境光相加得到一个整体的环境光

                
                //环境反射
                //--------------
                //Cube采样
                float3 CubeMap = texCUBElod(_CubeMap,CubeMapUV);//采样CubeMap
                //MatCap采样
                float3 MatCap = tex2Dlod(_MatCap,MatCapUV);//采样MatCap
                //切换Cubemap和MatCap
                float3 Reflection;//声明反射变量
                #if _REFLECTIONMODE_CUBEMAP//如果宏为CUBEMAP
                    Reflection = CubeMap;//反射为CubeMap
                #elif _REFLECTIONMODE_MATCAP//如果宏为MATCAP
                    Reflection = MatCap;//反射为MatCap
                #endif//if结束
                Reflection *= Fresnel * _ReflectionColor;//给反射赋予一个颜色
                
                //Albedo计算
                //Albedo = (颜色贴图+基础颜色+半兰伯特+高光) * 阴影 * 主灯光颜色
                float3 Albedo = (var_MainTex * _BaseColor * HalfLmabert  + Specular) * Shadow * _LightColor0.rgb;
                
              
                //Albedo = lerp(Albedo,Albedo * _LightColor0.rgb,Shadow);
                //环境计算
                //环境光 = (反射+环境光颜色) * AO贴图 * 环境强度
                float3 Environment = (Reflection  + AmbinetColor) * var_AmbientTex * _EnvironmentStrength;


                float3 finalRGB = Albedo + Environment;//最终颜色 = Albedo + 环境
                
                return finalRGB;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
