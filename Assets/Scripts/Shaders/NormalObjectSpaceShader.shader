Shader "Examples/NormalObjectSpaceShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex ("Texture", 2D) = "white" {}
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
            };

            sampler2D _MainTex;
            sampler2D _NormalTex;

            v2f vert (app_data i)
            {
                v2f o;
                o.vertex_ws = mul(unity_ObjectToWorld, i.vertex);
                o.vertex_cs = mul(UNITY_MATRIX_VP, o.vertex_ws);
                o.uv = i.uv;
                o.normal = mul(unity_ObjectToWorld, i.normal);
                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float3 normal = tex2D(_NormalTex, i.uv);
                normal = (normal - 0.5f) * 2.0f;
                normal = mul(unity_ObjectToWorld, normal);
                
                const float3 diffuse_light = _LightColor * max(0.0f, dot(normal, _LightDirection) * -1.0f);
                const float3 specular_light = _LightColor * max(0.0f, dot(reflect(normal, _LightDirection), normalize(_WorldSpaceCameraPos - i.vertex_ws)));
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
