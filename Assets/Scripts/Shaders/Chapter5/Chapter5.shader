Shader "Examples/Chapter5"
{
    Properties
    {
        _Color ("Main Color", Color) = (0.996, 0.712, 0.110, 1)
        [IntRange] _ReflectSharpness("Reflect Sharpness", Range(1, 100)) = 2
        _AmbientColor("Ambient", Color) = (0.2, 0.2, 0.2, 1)
    }
    
    SubShader
    {
        Pass
        {
            Name "Chapter3"
            // LightModeのパスタグの値はScriptableRenderContext.DrawRenderersのShaderTagIdと一致させる必要がある
            Tags {"LightMode" = "ExampleLightModeTag"}

            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;
            float4 _Color;
            float4 _AmbientColor;
            int _ReflectSharpness;

            // SunLightの位置
            float4 _WorldSpaceLightPos0;
            // SunLightの色
            float4 _LightColor0;

            // ワールド空間でのカメラ位置    
            float3 _WorldSpaceCameraPos;

            //
            float4 _PointLightColor;
            float3 _PointLightPos;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 positionWS : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 viewDir : TEXCOORD1;
            };

            Varyings vert(const Attributes input)
            {
                Varyings output;
                output.positionWS = mul(unity_ObjectToWorld, input.positionOS);
                output.positionCS = mul(unity_MatrixVP, output.positionWS);
                output.normalWS = normalize(mul((float3x3)unity_ObjectToWorld, input.normalOS));
                output.viewDir = normalize(_WorldSpaceCameraPos - output.positionWS.xyz);
                return output;
            }

            float3 DirectionalDiffuse(const float3 normal)
            {
                return max(0, dot(normal, _WorldSpaceLightPos0.xyz)) * _LightColor0.rgb;
            }

            float4 Ambient()
            {
                return _AmbientColor;
            }

            float3 DirectionalSpecular(const Varyings input)
            {
                const float3 reflectVec = reflect(-_WorldSpaceLightPos0.xyz, input.normalWS);
                float power = max(0, dot(input.viewDir, reflectVec));
                power = pow(power, _ReflectSharpness);
                
                return power * _LightColor0.xyz;
            }

            float4 frag(const Varyings input) : SV_Target
            {
                float4 color = _Color;

                // DirectionalLightの影響計算
                const float3 directionalDiffuseColor = DirectionalDiffuse(input.normalWS);
                const float3 directionalSpecularColor = DirectionalSpecular(input);

                // PointLightの影響計算
                const float3 pointDiffuseColor = 0;
                const float3 pointSpecularColor = 0;

                // 最終的なライトの影響計算
                const float3 totalDiffuseColor = directionalDiffuseColor + pointDiffuseColor;
                const float3 totalPointColor = directionalSpecularColor + pointSpecularColor;
                
                const float3 lightColor = totalDiffuseColor + totalPointColor + _AmbientColor.rgb;

                color.rgb *= lightColor;
                color.rgb = _PointLightColor;
                return color;
            }
            
            ENDHLSL
        }
    }
}
