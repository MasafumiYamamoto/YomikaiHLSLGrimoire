Shader "Examples/Chapter7"
{
    Properties
    {
        _BaseMap("BaseColor", 2D) = "white" {}
        _NormalMap("Normal", 2D) = "blue" {}
        //_SubSurface("Subsurface", float) = 0.2
        _MetallicMap("Metallic", float) = 0.2
        _SmoothnessMap("Smoothness", 2D) = "white" {}
        //_SpecularMap("Specular", 2D) = "gray" {}
        //_SpecularTint("SpecularTint", Color) = (1,1,1,1)
    }
    
    SubShader
    {
        Pass
        {
            Name "Chapter7"
            // LightModeのパスタグの値はScriptableRenderContext.DrawRenderersのShaderTagIdと一致させる必要がある
            Tags {"LightMode" = "ExampleLightModeTag"}
            
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "unityCG.cginc"

            // 各種テクスチャ用変数
            sampler2D _BaseMap;
            sampler2D _NormalMap;
            sampler2D _MetallicMap;
            sampler2D _SmoothnessMap;

            // float4x4 unity_MatrixVP;
            // float4x4 unity_ObjectToWorld;
            // float4x4 unity_WorldToObject;


            // SunLightの位置
            // float4 _WorldSpaceLightPos0;
            // SunLightの色
            float4 _LightColor0;

            // ワールド空間でのカメラ位置    
            // float3 _WorldSpaceCameraPos;

            const float PI = 3.14159;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangentOS : TANGENT;
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
                output.viewDir = normalize(_WorldSpaceCameraPos.xyz - output.positionWS.xyz);
                output.normalWS =  normalize(mul((float3x3)unity_ObjectToWorld, input.normalOS));
                output.tangentWS = normalize(mul((float3x3)unity_ObjectToWorld, input.tangentOS));
                output.biNormalWS = cross(input.normalOS, input.tangentOS) * input.tangentOS.w * unity_WorldTransformParams.w;
                output.biNormalWS = normalize(mul((float3x3)unity_ObjectToWorld, output.biNormalWS));
                return output;
            }

            float CalcDiffuseFromFresnel(const float3 worldNormal, const float3 surface2Light, const float3 toEye)
            {
                const float dotNL = saturate(dot(worldNormal, surface2Light));
                const float dotNV = saturate(dot(worldNormal, toEye));

                return dotNL*dotNV;
            }
                

            float4 frag(const Varyings input) : SV_Target
            {
                // ベースカラー
                const float4 baseColor = tex2D(_BaseMap, input.uv);

                float3 localNormal = UnpackNormal(tex2D(_NormalMap, input.uv));
                
                const float3 worldNormal = input.tangentWS * localNormal.x +
                    input.biNormalWS * localNormal.y +
                        input.normalWS * localNormal.z;

                float4 col = 1;
                col.rgb = worldNormal;
                return col;
                
                // スペキュラカラーはベースカラーと同じにする
                const float3 specularColor = baseColor.rgb;

                // 金属度
                const float metallic = tex2D(_MetallicMap, input.uv).r;

                // なめらかさ
                const float smoothness = tex2D(_SmoothnessMap, input.uv).r;

                // フレネル反射を考慮した拡散反射計算
                const float diffuseFromFresnel = CalcDiffuseFromFresnel(worldNormal, _WorldSpaceLightPos0, input.viewDir);

                // 正規化Lambert拡散反射を求める
                const float NdotL = saturate(dot(worldNormal, _WorldSpaceLightPos0));
                const float3 lambertDiffuse =  _LightColor0 * NdotL / PI;

                // 最終的な拡散反射を計算する
                const float3 diffuse = baseColor * diffuseFromFresnel * lambertDiffuse;

                float4 color = 1;
                color.rgb = worldNormal;
                
                return color;
            }
            
            ENDHLSL
        }
    }
}
