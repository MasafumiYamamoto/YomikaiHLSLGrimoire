Shader "Examples/SimpleUnlitColor"
{
    Properties
    {
       _Color ("Main Color", Color) = (0.996, 0.712, 0.110, 1)
    }
    
    SubShader
    {
        Pass
        {
            // LightModeのパスタグの値はScriptableRenderContext.DrawRenderersのShaderTagIdと一致させる必要がある
            Tags {"LightMode" = "ExampleLightModeTag"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4 _Color;

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(const Attributes input)
            {
                Varyings output;
                const float4 worldPos = mul(unity_ObjectToWorld, input.positionOS);
                output.positionCS = mul(unity_MatrixVP, worldPos);
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                return _Color;
            }
            
            ENDHLSL
            
            }
    }
}
