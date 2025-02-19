Shader "Universal RenderPipeline/Custom/CombinedGlowDissolveAtEnd"
{
    Properties
    {
        // Glow properties
        _BaseColor("Base Color (HDR)", Color) = (1,1,1,1)
        _GlowColor("Glow Color (HDR)", Color) = (1,1,1,1)
        _GlowIntensity("Glow Intensity", Range(0,10)) = 3
        _GlowRadius("Glow Radius", Range(0,2)) = 0.5
        _GlowSoftness("Glow Softness", Range(0.1,8)) = 2
        _Alpha("Opacity", Range(0,1)) = 1
        _HaloSize("Halo Size", Range(0,1)) = 0.1
        _HaloIntensity("Halo Intensity", Range(0,20)) = 5

        // Dissolve properties
        _DissolveAmount("Dissolve Amount", Range(0,1)) = 0.5
        _DissolveScale("Dissolve Scale", Range(0,500)) = 30
        _OutlineThickness("Outline Thickness", Range(0,1)) = 0.1
        _OutlineColor("Outline Color (HDR)", Color) = (0.014, 0.687, 1, 1)
        _DissolveEdgeStart("Dissolve Edge Start", Range(0,1)) = 0.8  // UV.x value where dissolve begins
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }

        //=====================================================
        // Pass 1: Base trail with inner glow + end-only dissolve
        //=====================================================
        Pass
        {
            Name "BaseTrail"
            Tags { "LightMode"="UniversalForward" }
            Blend One One
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex BaseVert
            #pragma fragment BaseFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Simple noise function (basic value noise)
            float SimpleNoise(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);
                float a = frac(sin(dot(i, float2(12.9898,78.233)))*43758.5453);
                float b = frac(sin(dot(i+float2(1,0), float2(12.9898,78.233)))*43758.5453);
                float c = frac(sin(dot(i+float2(0,1), float2(12.9898,78.233)))*43758.5453);
                float d = frac(sin(dot(i+float2(1,1), float2(12.9898,78.233)))*43758.5453);
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            // Glow parameters
            float4 _BaseColor;
            float4 _GlowColor;
            float  _GlowIntensity;
            float  _GlowRadius;
            float  _GlowSoftness;
            float  _Alpha;

            // Dissolve parameters
            float  _DissolveAmount;
            float  _DissolveScale;
            float  _OutlineThickness;
            float4 _OutlineColor;
            float  _DissolveEdgeStart;

            Varyings BaseVert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 BaseFrag(Varyings IN) : SV_Target
            {
                // --- Glow Computation ---
                half3 baseCol = _BaseColor.rgb;
                float2 centerUV = IN.uv - 0.5;
                float dist = length(centerUV) * 2.0;
                float glowMask = saturate(1.0 - pow(dist / _GlowRadius, _GlowSoftness));
                half3 innerGlow = _GlowColor.rgb * glowMask * _GlowIntensity;
                half3 glowColor = baseCol + innerGlow;

                // --- Dissolve Computation ---
                // Use noise to generate a dissolve value
                float noise = SimpleNoise(IN.uv * _DissolveScale);
                float dissolveNoise = smoothstep(_DissolveAmount, _DissolveAmount + _OutlineThickness, noise);

                // Create a mask so that dissolve is applied only at the end of the trail (using uv.x)
                float trailMask = smoothstep(_DissolveEdgeStart, 1.0, IN.uv.x);
                float finalDissolve = dissolveNoise * trailMask;

                // Blend between the glow color and the outline color based on the dissolve
                half3 finalColor = lerp(glowColor, _OutlineColor.rgb, finalDissolve);
                float finalAlpha = _Alpha * (1.0 - finalDissolve);

                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }

        //=====================================================
        // Pass 2: Halo pass with end-only dissolve effect
        //=====================================================
        Pass
        {
            Name "Halo"
            Tags { "LightMode"="UniversalForward" }
            Blend One One
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex HaloVert
            #pragma fragment HaloFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float SimpleNoise(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);
                float a = frac(sin(dot(i, float2(12.9898,78.233)))*43758.5453);
                float b = frac(sin(dot(i+float2(1,0), float2(12.9898,78.233)))*43758.5453);
                float c = frac(sin(dot(i+float2(0,1), float2(12.9898,78.233)))*43758.5453);
                float d = frac(sin(dot(i+float2(1,1), float2(12.9898,78.233)))*43758.5453);
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            float4 _GlowColor;
            float _HaloSize;
            float _HaloIntensity;
            float _Alpha;

            float  _DissolveAmount;
            float  _DissolveScale;
            float  _OutlineThickness;
            float4 _OutlineColor;
            float  _DissolveEdgeStart;

            Varyings HaloVert(Attributes IN)
            {
                Varyings OUT;
                float2 offset = (IN.uv - 0.5) * _HaloSize;
                float4 pos = IN.positionOS;
                pos.xy += offset;
                OUT.positionHCS = TransformObjectToHClip(pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 HaloFrag(Varyings IN) : SV_Target
            {
                half3 haloCol = _GlowColor.rgb * _HaloIntensity;
                float noise = SimpleNoise(IN.uv * _DissolveScale);
                float dissolveNoise = smoothstep(_DissolveAmount, _DissolveAmount + _OutlineThickness, noise);
                float trailMask = smoothstep(_DissolveEdgeStart, 1.0, IN.uv.x);
                float finalDissolve = dissolveNoise * trailMask;
                half3 finalColor = lerp(haloCol, _OutlineColor.rgb, finalDissolve);
                float finalAlpha = _Alpha * 0.5 * (1.0 - finalDissolve);
                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }
    }
    FallBack "Universal Forward"
}
