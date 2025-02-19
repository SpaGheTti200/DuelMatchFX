Shader "Universal RenderPipeline/Custom/TrailGradientEdgeAdjustable_OuterTransparent"
{
    Properties
    {
        // Base colors for the trail gradient
        _LightBlue("Start Color (Light Blue)", Color) = (0.6, 0.8, 1, 1)
        _DarkBlue("End Color (Dark Blue)", Color) = (0, 0.2, 0.5, 1)
        _Alpha("Opacity", Range(0,1)) = 0.5

        // Controls how much darker the edges become (more intense at the trail’s end)
        _EdgeIntensity("Edge Intensity", Range(0,1)) = 1

        // Controls where the color transition occurs along the trail (uv.x axis)
        _LerpStart("Lerp Start", Range(0,1)) = 0.0
        _LerpEnd("Lerp End", Range(0,1)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Name "TrailGradientEdgeAdjustable_OuterTransparent"
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Vertex input structure
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            // Data passed from vertex to fragment
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            // Material properties
            float4 _LightBlue;
            float4 _DarkBlue;
            float  _Alpha;
            float  _EdgeIntensity;
            float  _LerpStart;
            float  _LerpEnd;

            // Vertex shader: transform and pass UVs
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            // Fragment shader: compute color gradient, edge darkening, and extra outer transparency
            half4 frag(Varyings IN) : SV_Target
            {
                // Compute a "lengthFactor" for the trail gradient (from _LerpStart to _LerpEnd)
                float lengthFactor = saturate((IN.uv.x - _LerpStart) / max(0.0001, (_LerpEnd - _LerpStart)));

                // Base color: blend from _LightBlue at the start to _DarkBlue at the end.
                float3 baseColor = lerp(_LightBlue.rgb, _DarkBlue.rgb, lengthFactor);

                // Compute edge distance from the vertical center (uv.y = 0.5)
                float edgeDist = abs(IN.uv.y - 0.5) * 2.0;  // 0 at center, 1 at edges

                // An edge factor that increases with distance and with trail progression.
                float edgeFactor = saturate(edgeDist * lengthFactor * _EdgeIntensity);

                // Compute outerAlpha: use a smoothstep so that the alpha falls off more steeply as we approach the edges.
                // Here, when edgeDist is low (near 0.0) 1.0 - edgeDist is near 1 (fully opaque),
                // and when edgeDist is high (near 1.0) it falls toward 0.
                float outerAlpha = smoothstep(0.2, 0.8, 1.0 - edgeDist);

                // Final color blends baseColor toward _DarkBlue on the edges.
                float3 finalColor = lerp(baseColor, _DarkBlue.rgb, edgeFactor);

                // Combine the original alpha modulation with the extra outer transparency.
                float finalAlpha = _Alpha * (1.0 - edgeFactor) * outerAlpha;

                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }
    }
    FallBack "Universal Forward"
}
