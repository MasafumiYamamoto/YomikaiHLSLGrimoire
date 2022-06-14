Shader "Examples/CharacterShader2"
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

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4 _LightDirection;
            float4 _LightColor;
            float3 _WorldSpaceCameraPos;

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
            };

            sampler2D _MainTex;

            v2f vert (app_data i)
            {
                v2f o;
                o.vertex_ws = mul(unity_ObjectToWorld, i.vertex);
                o.vertex_cs = mul(unity_MatrixVP, o.vertex_ws);
                o.uv = i.uv;
                o.normal = mul(unity_ObjectToWorld, i.normal);
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
                return tex2D(_MainTex, i.uv) * light;
            }
            ENDHLSL
        }
    }
}
