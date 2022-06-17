Shader "Examples/CharacterShader3"
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
            float4 _LightPosition;
            float4 _LightDirection;
            float4 _LightColor;
            float _LightRange;
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

            float3 calcLambertDiffuse(float3 lightDir, float4 lightColor, float3 normal)
            {
                return lightColor * max(0.0f, dot(normal, lightDir) * -1.0f);
            }

            float3 calcPhongSpecular(float3 lightDir, float4 lightColor, float3 normal, float3 worldPos)
            {
                return lightColor * max(0.0f, dot(reflect(normal, lightDir), normalize(_WorldSpaceCameraPos - worldPos)));
            }

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
                const float3 lightDir = normalize(i.vertex_ws - _LightPosition);
                const float3 diffPoint = calcLambertDiffuse(lightDir, _LightColor, i.normal);
                const float3 specularPoint = calcPhongSpecular(lightDir, _LightColor, i.normal, i.vertex_ws);
                const float distance = length(i.vertex_ws - _LightPosition);
                float efficiency = max(0.0f, 1.0f - 1.0f / _LightRange * distance);
                efficiency = pow(efficiency, 2.0f);
                
                return tex2D(_MainTex, i.uv) * (diffPoint * efficiency + specularPoint * efficiency);
            }
            ENDHLSL
        }
    }
}
