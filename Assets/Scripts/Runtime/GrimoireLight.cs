using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace Runtime
{
    public class GrimoireLight
    {
        private const string BufferName = "Lighting";
        private const int MaxDirectionalLightCount = 4;

        /// <summary>
        ///     フレーム中で存在する非Directionalライトの数
        /// </summary>
        private const int MaxOtherLightCount = 64;

        /// <summary>
        ///     サンライト以外の平行光源設定
        /// </summary>
        private static readonly Vector4[] AdditionalDirectionalLightColors = new Vector4[MaxDirectionalLightCount];

        private static readonly Vector4[] AdditionalDirectionalLightDirections = new Vector4[MaxDirectionalLightCount];

        private static readonly int AdditionalDirectionalLightCountId =
            Shader.PropertyToID("_AdditionalDirectionalLightCount");

        private static readonly int AdditionalDirectionalLightColorsId =
            Shader.PropertyToID("_AdditionalDirectionalLightColors");

        private static readonly int AdditionalDirectionalLightDirectionsId =
            Shader.PropertyToID("_AdditionalDirectionalLightDirections");

        /// <summary>
        ///     非平行光源設定
        /// </summary>
        private static readonly int OtherLightCountId = Shader.PropertyToID("_OtherLightCount");

        private static readonly int OtherLightColorsId = Shader.PropertyToID("_OtherLightColors");
        private static readonly int OtherLightPositionsId = Shader.PropertyToID("_OtherLightPositions");
        private static readonly int OtherLightDirectionsId = Shader.PropertyToID("_OtherLightDirections");


        private static readonly Vector4[] OtherLightColors = new Vector4[MaxOtherLightCount];

        /// <summary>
        ///     WにRangeを入れている
        /// </summary>
        private static readonly Vector4[] OtherLightPositions = new Vector4[MaxOtherLightCount];

        private static readonly Vector4[] OtherLightDirections = new Vector4[MaxOtherLightCount];

        private readonly CommandBuffer _buffer = new()
        {
            name = BufferName
        };

        private CullingResults _cullingResults;

        public void Setup(ScriptableRenderContext context, CullingResults cullingResults)
        {
            _cullingResults = cullingResults;
            _buffer.BeginSample(BufferName);
            SetupLights();
            _buffer.EndSample(BufferName);
            context.ExecuteCommandBuffer(_buffer);
            _buffer.Clear();
        }

        /// <summary>
        ///     シーン中のライト情報を設定する
        /// </summary>
        private void SetupLights()
        {
            var visibleLights = _cullingResults.visibleLights;
            var additionalDirectionalLightCount = 0;
            var otherLightCount = 0;
            for (var i = 0; i < visibleLights.Length; i++)
            {
                var visibleLight = visibleLights[i];
                switch (visibleLight.lightType)
                {
                    case LightType.Spot:
                        if (otherLightCount < MaxOtherLightCount) SetupSpotLight(otherLightCount++, ref visibleLight);
                        break;
                    case LightType.Directional:
                        if (visibleLight.light == RenderSettings.sun)
                            // サンライトは別枠で計算してあるので除外
                            continue;
                        if (additionalDirectionalLightCount < MaxDirectionalLightCount)
                            SetupDirectionalLight(additionalDirectionalLightCount++, ref visibleLight);
                        break;
                    case LightType.Point:
                        if (otherLightCount < MaxOtherLightCount) SetupPointLight(otherLightCount++, ref visibleLight);
                        break;
                    case LightType.Area:
                        break;
                    case LightType.Disc:
                        break;
                    default:
                        throw new ArgumentOutOfRangeException();
                }
            }

            // 求めたライト情報をシェーダに送る
            _buffer.SetGlobalInt(AdditionalDirectionalLightCountId, additionalDirectionalLightCount);
            if (additionalDirectionalLightCount > 0)
            {
                _buffer.SetGlobalVectorArray(AdditionalDirectionalLightColorsId, AdditionalDirectionalLightColors);
                _buffer.SetGlobalVectorArray(AdditionalDirectionalLightDirectionsId,
                    AdditionalDirectionalLightDirections);
            }

            _buffer.SetGlobalInt(OtherLightCountId, otherLightCount);
            if (otherLightCount > 0)
            {
                _buffer.SetGlobalVectorArray(OtherLightColorsId, OtherLightColors);
                _buffer.SetGlobalVectorArray(OtherLightPositionsId, OtherLightPositions);
                _buffer.SetGlobalVectorArray(OtherLightDirectionsId, OtherLightDirections);
            }
        }

        private static void SetupDirectionalLight(int index, ref VisibleLight visibleLight)
        {
            AdditionalDirectionalLightColors[index] = visibleLight.light.color;
            AdditionalDirectionalLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        }

        /// <summary>
        ///     点光源の初期化
        /// </summary>
        /// <param name="index"></param>
        /// <param name="visibleLight"></param>
        private static void SetupPointLight(int index, ref VisibleLight visibleLight)
        {
            OtherLightColors[index] = visibleLight.light.color;
            var position = visibleLight.localToWorldMatrix.GetColumn(3);
            position.w = visibleLight.range;
            OtherLightPositions[index] = position;
        }

        /// <summary>
        ///     スポットライトの初期化
        /// </summary>
        /// <param name="index"></param>
        /// <param name="visibleLight"></param>
        private static void SetupSpotLight(int index, ref VisibleLight visibleLight)
        {
            SetupPointLight(index, ref visibleLight);
            var direction = -visibleLight.localToWorldMatrix.GetColumn(2);
            direction.w = visibleLight.light.spotAngle;
            OtherLightDirections[index] = direction;
        }
    }
}