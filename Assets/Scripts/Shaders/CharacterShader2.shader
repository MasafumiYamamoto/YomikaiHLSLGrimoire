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

            struct appData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 normal : NORMAL;
            };

            sampler2D _MainTex;

            v2f vert (appData i)
            {
                v2f o;
                const float4 worldPos = mul(unity_ObjectToWorld, i.vertex);
                o.vertex = mul(unity_MatrixVP, worldPos);
                o.uv = i.uv;
                o.normal = mul(unity_ObjectToWorld, i.normal);
                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv) * _LightColor * max(0.0f, dot(i.normal, _LightDirection) * -1.0f);
            }
            ENDHLSL
        }
    }
}
