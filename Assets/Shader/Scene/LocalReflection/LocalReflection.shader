Shader "Unlit/LocalReflection"
{
    Properties
    {   
        _MainCube("MainCube",Cube) = "cube"{}
        _BoxSize("BoxSize",vector) = (1,1,1,1)
        _BoxPos("BoxPos",vector) = (0,0,0,0)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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
                float4 worldPos:TEXCOORD2;
                float3 worldNormal:TEXCOORD3;
                float3 worldView:TEXCOORD4;
            };


            uniform float4 _EnviCubeMapPos;
            float4 _BoxSize,_BoxPos;
            samplerCUBE _MainCube;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldView = o.worldPos - _WorldSpaceCameraPos;
                return o;
            }

            fixed3 frag (v2f i) : SV_Target
            {
                //准备向量
                float3 worldPos = i.worldPos;
                float3 viewDir = normalize(i.worldView);
                float3 cameraPos = _WorldSpaceCameraPos;
                float3 normalDir = normalize(i.worldNormal);
                float3 reflectDir = reflect(viewDir,normalDir);
                //LocalReflection纠正
                float3 intersectMaxPointPlanes = (_BoxSize - worldPos) / reflectDir;
                float3 intersectMinPointPlanes = (-_BoxSize - worldPos) / reflectDir;
                float3 largestParams = max(intersectMaxPointPlanes, intersectMinPointPlanes);
                float distToIntersect = min(min(largestParams.x, largestParams.y), largestParams.z);
                float3 intersectPositionWS = worldPos + reflectDir * distToIntersect;
                float3 localRefDir = intersectPositionWS  - _BoxPos.xyz;
                //采样cube
                float3 var_Cube = texCUBE(_MainCube, localRefDir);
                




                return var_Cube;
            }
            ENDCG
        }
    }
}
