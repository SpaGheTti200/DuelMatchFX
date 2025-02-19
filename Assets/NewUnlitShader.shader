Shader "Universal RenderPipeline/Custom/BetterGlowTrail"
{
    Properties
    {
        // Base color for the trail (use HDR color picker)
        _BaseColor("Base Color (HDR)", Color) = (1,1,1,1)

        // Glow color (HDR) for inner glow and halo
        _GlowColor("Glow Color (HDR)", Color) = (1,1,1,1)

        // Multiplier for inner glow brightness
        _GlowIntensity("Glow Intensity", Range(0,10)) = 3

        // Controls how far from the center the inner glow extends
        _GlowRadius("Glow Radius", Range(0,2)) = 0.5

        // Controls how sharply the inner glow falls off
        _GlowSoftness("Glow Softness", Range(0.1,8)) = 2

        // Overall opacity for both passes
        _Alpha("Opacity", Range(0,1)) = 1

        // (Halo Pass) How far to expand the geometry for the halo effect
        _HaloSize("Halo Size", Range(0,1)) = 0.1

        // (Halo Pass) Extra multiplier for the halo brightness
        _HaloIntensity("Halo Intensity", Range(0,20)) = 5
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        //===========================================
        // Pass 1: Base trail with inner glow effect
        //===========================================
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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            float4 _BaseColor;
            float4 _GlowColor;
            float  _GlowIntensity;
            float  _GlowRadius;
            float  _GlowSoftness;
            float  _Alpha;

            Varyings BaseVert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 BaseFrag(Varyings IN) : SV_Target
            {
                // Base color of the trail
                half3 baseCol = _BaseColor.rgb;

                // Compute a radial gradient in UV space
                // (assumes the UV coordinates run from 0 to 1)
                float2 centerUV = IN.uv - 0.5;
                float dist = length(centerUV) * 2.0; // scale distance so the effect covers more area
                float glowMask = saturate(1.0 - pow(dist / _GlowRadius, _GlowSoftness));

                // Inner glow contribution
                half3 innerGlow = _GlowColor.rgb * glowMask * _GlowIntensity;

                // Combine base color and inner glow
                half3 finalColor = baseCol + innerGlow;

                return half4(finalColor, _Alpha);
            }
            ENDHLSL
        }

        //===========================================
        // Pass 2: Extra halo to boost overall glow
        //===========================================
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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            float4 _GlowColor;
            float _HaloSize;
            float _HaloIntensity;
            float _Alpha;

            Varyings HaloVert(Attributes IN)
            {
                Varyings OUT;
                // Expand the geometry slightly based on the UV coordinates
                // (Assumes the trail is a billboard so object space XY roughly maps to screen space.)
                float2 offset = (IN.uv - 0.5) * _HaloSize;
                float4 pos = IN.positionOS;
                pos.xy += offset;
                OUT.positionHCS = TransformObjectToHClip(pos);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 HaloFrag(Varyings IN) : SV_Target
            {
                // Output a pure glow (halo) color.
                // Using a reduced alpha here so it blends smoothly with the BaseTrail.
                return half4(_GlowColor.rgb * _HaloIntensity, _Alpha * 0.5);
            }
            ENDHLSL
        }
    }
    FallBack "Universal Forward"
}