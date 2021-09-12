Shader "thinfilm" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _AlobedoColor("_AlobedoColor",Color) = (0.0,0.0,0.0,0.0)
        _Ramp ("Shading Ramp", 2D) = "gray" {}
        _SurfColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1) 
        _SpecExpon ("Spec Power", Range (0, 125)) = 12
        _FilmDepth ("Film Depth", Range (0, 1)) = 0.05
    }
    SubShader {
        Tags { "RenderType" = "Opaque" }
        CGPROGRAM
        #pragma surface surf Ramp

        sampler2D _Ramp;
        float _SurfColor;
        float _SpecExpon;
        float _FilmDepth;
        float4 _AlobedoColor;


        half4 LightingRamp (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {

            half3 Hn = normalize (lightDir + viewDir);
            half3 normal = normalize(s.Normal);
            half ndl = dot (normal, lightDir);
            half ndh = dot (normal, Hn);
            half ndv = dot (normal, viewDir);

            float3 diff = max(0,ndl).xxx;

            float nh = max (0, ndh);

            float3 spec = pow (nh, _SpecExpon).xxx;

            //*viewdepth即光程差，这里用光在薄膜中行程长度近似。*
            float viewdepth = _FilmDepth/ndv*2.0;
            half3 ramp = tex2D (_Ramp, viewdepth.xx).rgb;
            half4 c;
            c.rgb = (s.Albedo*_SurfColor * diff + ramp * spec) *(atten);
            c.a = s.Alpha;
            return c;
        }

        struct Input {
            float2 uv_MainTex;
            half3 viewDir;
        };
        sampler2D _MainTex;
        void surf (Input IN, inout SurfaceOutput o) {
            o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb * _AlobedoColor;
            
        }
        ENDCG
    }
    Fallback "Diffuse"
}
