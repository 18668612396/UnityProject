Shader "Unlit/Sun"
{
    Properties
    {
        [Toggle]_SunAndMoon("是太阳还是月亮(打勾是太阳)",int) = 0
        _MainTex ("Texture", 2D) = "white" {}
        _SunIntensity("太阳强度",Range(1,10)) = 1
        _SunAndMoonSize("太阳大小",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Blend One OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            float2 RotateAroundYInDegrees (float2 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return mul(m,vertex);
            }
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _SunIntensity;
            float _SunAndMoonSize;
            int _SunAndMoon;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //旋转矩阵
                float rotator = abs(normalize(_WorldSpaceCameraPos.xyz)) * _SunAndMoon * 3;
                float2 uv = (v.uv.xy - float2(0.5, 0.5)) / _SunAndMoonSize;
                uv = float2(uv.x * cos(rotator) - uv.y * sin(rotator), 
                uv.x * sin(rotator) + uv.y * cos(rotator));
                uv += float2(0.5, 0.5);
                
                o.uv = uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {


                fixed4 var_MainTex = tex2D(_MainTex, i.uv) ;
                var_MainTex *= var_MainTex;
                float4 finalColor = var_MainTex* _LightColor0.rgba * _SunIntensity;
                return finalColor;
            }
            ENDCG
        }
    }
}
