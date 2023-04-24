Shader "Examples/CharacterShader6"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ExampleLightModeTag"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            float4 _LightPosition;
            float4 _LightDirection;
            float4 _LightColor;

            struct app_data
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex_cs : SV_POSITION;
                float4 vertex_ws : TEXCORD0;
                float2 uv : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 normalInView : TECOORD3;
            };

            sampler2D _MainTex;

            v2f vert (app_data i)
            {
                v2f o;
                o.vertex_ws = mul(unity_ObjectToWorld, i.vertex);
                o.vertex_cs = mul(UNITY_MATRIX_VP, o.vertex_ws);
                o.uv = i.uv;
                o.normal = mul(unity_ObjectToWorld, i.normal);
                o.normalInView = mul(UNITY_MATRIX_V, o.normal);
                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                const float3 diffuse_light = _LightColor * max(0.0f, dot(i.normal, _LightDirection) * -1.0f);
                const float3 specular_light = _LightColor * max(0.0f, dot(reflect(i.normal, _LightDirection), normalize(_WorldSpaceCameraPos - i.vertex_ws)));
                float3 light = diffuse_light + pow(specular_light, 5);
                light.x += 0.2;
                light.y += 0.2;
                light.z += 0.2;
                
                float power1 = 1.0f - max(0.0f, dot(-_LightDirection, i.normal));
                float power2 = 1.0f - max(0.0f, i.normalInView.z * 1.0f);
                float limPower = power1 * power2;
                limPower = pow(limPower, 1.5f);

                float3 limColor = limPower * _LightColor;
                light += limColor;
                
                return tex2D(_MainTex, i.uv) * light;
            }
            ENDHLSL
        }
    }
}
