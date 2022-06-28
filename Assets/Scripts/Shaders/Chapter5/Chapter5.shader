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

            // 追加のDirectionalLight
            #define MaxAdditionalDirectionalLightCount = 4;
            int _AdditionalDirectionalLightCount;
            float4 _AdditionalDirectionalLightColors[4];
            float4 _AdditionalDirectionalLightDirections[4];

            // 非平行光源
            #define MAX_OTHER_LIGHT_COUNT = 64;
            int _OtherLightCount;
            float4 _OtherLightColors[64];
            float4 _OtherLightPositions[64];
            float4 _OtherLightDirections[64];

            int GetOtherLightCount()
            {
                return _OtherLightCount;
            }

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
                output.viewDir = normalize(_WorldSpaceCameraPos.xyz - output.positionWS.xyz);
                return output;
            }

            float3 RimEffect(const Varyings input, const float3 directionalLightDirection, const float3 lightColor)
            {
                const float directionalLightRimPower = 1 - max(0, dot(input.normalWS, directionalLightDirection));
                const float eyeRimPower = 1 - max(0, dot(input.normalWS, input.viewDir));
                float rimPower = directionalLightRimPower * eyeRimPower;
                rimPower = pow(rimPower, 1.3);

                return rimPower * lightColor;
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

            float3 OtherLightDiffuse(const float3 pos, const float3 normal, const int j)
            {
                const float3 direction = _OtherLightPositions[j].xyz - pos;
                const float3 lightVec = normalize(direction);
                const float distanceAttenuation = max(0, 1 - 1/_OtherLightPositions[j].w*length(direction));

                float angleAttenuation = 1;
                // Spot Angleが1以上の場合はスポットライトとして、角度による減衰を入れる
                // 適切な分岐方法どうやるのかは気になるところ
                if (_OtherLightDirections[j].w > 0)
                {
                    const float angle = abs(acos(dot(lightVec, _OtherLightDirections[j])));
                    angleAttenuation = max(0, 1 - angle/radians(_OtherLightDirections[j].w/2));
                }

                return max(0, dot(lightVec, normal)) * distanceAttenuation * angleAttenuation  * _OtherLightColors[j].rgb;
            }

            float3 OtherLightSpecular(const Varyings input, const int j)
            {
                const float3 direction = _OtherLightPositions[j] - input.positionWS;
                const float distanceAttenuation = max(0, 1 - 1/_OtherLightPositions[j].w*length(direction));
                const float3 reflectVec = reflect(-normalize(direction), input.normalWS);
                const float3 lightVec = normalize(direction);
                float power = max(0, dot(input.viewDir, reflectVec));

                float angleAttenuation = 1;
                // Spot Angleが1以上の場合はスポットライトとして、角度による減衰を入れる
                // 適切な分岐方法どうやるのかは気になるところ
                if (_OtherLightDirections[j].w > 0)
                {
                    const float angle = abs(acos(dot(lightVec, _OtherLightDirections[j])));
                    angleAttenuation = max(0, 1 - angle/radians(_OtherLightDirections[j].w/2));
                }

                
                power *= distanceAttenuation * angleAttenuation;
                power = pow(power, _ReflectSharpness);

                return power * _OtherLightColors[j].rgb;
            }

            float4 frag(const Varyings input) : SV_Target
            {
                float4 color = _Color;

                // DirectionalLightの影響計算
                const float3 directionalDiffuseColor = DirectionalDiffuse(input.normalWS);
                const float3 directionalSpecularColor = DirectionalSpecular(input);

                // リムライトの影響計算
                const float3 rimColor = RimEffect(input, _WorldSpaceLightPos0.xyz, _LightColor0.xyz);

                // PointLightの影響計算
                float3 pointDiffuseColor = 0;
                float3 pointSpecularColor = 0;
                for (int j = 0; j < GetOtherLightCount(); j++)
                {
                    pointDiffuseColor += OtherLightDiffuse(input.positionWS, input.normalWS, j);
                    pointSpecularColor += OtherLightSpecular(input, j);
                }

                // 最終的なライトの影響計算
                const float3 totalDirectionalColor = directionalDiffuseColor + directionalSpecularColor + rimColor;
                const float3 totalPointColor = pointDiffuseColor + pointSpecularColor;
                
                const float3 lightColor = totalDirectionalColor + totalPointColor + _AmbientColor.rgb;

                color.rgb *= lightColor;
                return color;
            }
            
            ENDHLSL
        }
    }
}
