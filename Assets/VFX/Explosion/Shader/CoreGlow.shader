Shader "Custom/ParticleGlowCircle"
{
    Properties
    {
        _MainTex ("Particle Texture", 2D) = "white" {}
        _TintColor ("Tint Color", Color) = (1,1,1,1)
        _GlowColor ("Glow Color", Color) = (1,1,1,1)
        _GlowFalloff ("Glow Falloff", Range(1,10)) = 2.0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        // Use additive blending for a bright, glowing look.
        Blend One One
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _TintColor;
            fixed4 _GlowColor;
            float _GlowFalloff;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color * _TintColor;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample the texture.
                fixed4 tex = tex2D(_MainTex, i.uv);
                
                // Calculate radial distance from the center (0.5,0.5) of the particle.
                float2 center = float2(0.5, 0.5);
                float dist = distance(i.uv, center);
                
                // Discard fragments outside the circle (radius = 0.5).
                if (dist > 0.5)
                    discard;
                
                // Compute a glow factor that is highest at the center and falls off.
                float glow = saturate(pow(1.0 - dist, _GlowFalloff));
                
                // Combine the base texture with the additional glow.
                fixed4 col = tex * i.color;
                col.rgb += _GlowColor.rgb * glow;
                col.a = tex.a * i.color.a;
                return col;
            }
            ENDCG
        }
    }
}
