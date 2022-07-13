Shader "Examples/Chapter6"
{
    Properties
    {
        _AlbedoMap("Albedo", 2D) = "white"
        _NormalMap("Normal", 2D) = "blue"
    }
    
    SubShader
    {
        Pass
        {
            Name "Chapter6"
            // LightModeのパスタグの値はScriptableRenderContext.DrawRenderersのShaderTagIdと一致させる必要がある
            Tags {"LightMode" = "ExampleLightModeTag"}

            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            // 各種テクスチャ用の変数
            sampler2D _AlbedoMap;
            sampler2D _NormalMap;

            // SunLightの位置
            float4 _WorldSpaceLightPos0;
            // SunLightの色
            float4 _LightColor0;

            // ワールド空間でのカメラ位置    
            float3 _WorldSpaceCameraPos;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionWS : TEXCOORD1;
                float3 normalWS : NORMAL;
                float3 viewDir : TEXCOORD2;
                float3 tangentWS : TEXCOORD3; // 接ベクトル
                float3 biNormalWS : TEXCOORD4; // 従ベクトル
            };

            Varyings vert(const Attributes input)
            {
                Varyings output;
                output.positionWS = mul(unity_ObjectToWorld, input.positionOS);
                output.uv = input.uv;
                output.positionCS = mul(unity_MatrixVP, output.positionWS);
                output.normalWS = normalize(mul((float3x3)unity_ObjectToWorld, input.normalOS));
                output.viewDir = normalize(_WorldSpaceCameraPos.xyz - output.positionWS.xyz);
                output.tangentWS = normalize(mul((float3x3)unity_ObjectToWorld, input.tangent.xyz));
                output.biNormalWS = cross(output.normalWS, output.tangentWS);
                return output;
            }

            float3 DirectionalDiffuse(const float3 normal)
            {
                return max(0, dot(normal, _WorldSpaceLightPos0.xyz)) * _LightColor0.rgb;
            }
            
            float4 frag(const Varyings input) : SV_Target
            {
                float4 color = tex2D(_AlbedoMap, input.uv);
                float3 localNormal = tex2D(_NormalMap, input.uv).xyz;
                localNormal = (localNormal - 0.5f) * 2;
                const float3 worldNormal = input.tangentWS * localNormal.x + input.biNormalWS * localNormal.y + input.normalWS * localNormal.z;

                // DirectionalLightの影響計算
                const float3 directionalDiffuseColor = DirectionalDiffuse(worldNormal);

                // 最終的なライトの影響計算
                const float3 totalDirectionalColor = directionalDiffuseColor;
                
                const float3 lightColor = totalDirectionalColor;

                color.rgb *= lightColor;
                return color;
            }
            
            ENDHLSL
        }
    }
}
