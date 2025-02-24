Shader "Custom/LineRendererCustomizableOuterEdge_TilingOffset" {
    Properties {
        _MainTex ("Particle Texture", 2D) = "white" {}
        _TilingOffset ("Texture Tiling & Offset (xy = tiling, zw = offset)", Vector) = (1,1,0,0)
        _InnerColor ("Inner Color", Color) = (1,1,1,1)
        _OuterColor ("Outer Color", Color) = (1,1,1,1)
        _EdgeWidth ("Edge Width", Range(0,0.5)) = 0.1
        _GradientExponent ("Gradient Exponent", Range(1,10)) = 1.0
        _AlphaMultiplier ("Alpha Multiplier", Range(0,1)) = 1.0
    }
    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend One One
        Cull Off
        Lighting Off
        ZWrite Off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _TilingOffset;
            fixed4 _InnerColor;
            fixed4 _OuterColor;
            float _EdgeWidth;
            float _GradientExponent;
            float _AlphaMultiplier;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // Manually apply tiling and offset from the exposed vector property.
                o.uv = v.uv * _TilingOffset.xy + _TilingOffset.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // Sample the texture using the custom tiling and offset UV.
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // Calculate distance from the closest horizontal edge.
                float d = min(i.uv.x, 1.0 - i.uv.x);
                // Create a factor that is 1 at the edge (d==0) and fades to 0 over _EdgeWidth.
                float factor = 1.0 - smoothstep(0.0, _EdgeWidth, d);
                // Adjust the gradient curve.
                factor = pow(factor, _GradientExponent);

                // Blend between inner and outer colors.
                fixed4 finalColor = lerp(_InnerColor, _OuterColor, factor);
                finalColor.a *= _AlphaMultiplier;

                return finalColor * texColor;
            }
            ENDCG
        }
    }
}
