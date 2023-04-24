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

            float3 calcDirectionalLight(v2f i)
            {
                const float3 diffuse_light = _LightColor * max(0.0f, dot(i.normal, _LightDirection) * -1.0f);
                const float3 specular_light = _LightColor * max(0.0f, dot(reflect(i.normal, _LightDirection), normalize(_WorldSpaceCameraPos - i.vertex_ws)));
                float3 light = diffuse_light + pow(specular_light, 5);
                light.x += 0.2;
                light.y += 0.2;
                light.z += 0.2;
                return light;
            }

            float3 frag (v2f i) : SV_Target
            {
                float3 light = calcDirectionalLight(i);

                float t = dot(i.normal, float3(0,1,0));
                t = (t + 1.0f) / 2.0f;
                float3 hemiLight = lerp(float3(1,0,0), float3(160.0f / 255.0f, 216.0f / 255.0f, 239.0f / 255.0f), t);

                light += hemiLight;
                
                return tex2D(_MainTex, i.uv) * light;
            }
            ENDHLSL
        }
    }
}
