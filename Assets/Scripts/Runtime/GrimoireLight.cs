using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal.Internal;

namespace Runtime
{
    public class GrimoireLight
    {
        private const string BufferName = "Lighting";
        private const int MaxDirectionalLightCount = 4;
        
        private CullingResults _cullingResults;

        private static readonly Vector4[] DirectionalLightColors = new Vector4[MaxDirectionalLightCount];
        private static readonly Vector4[] DirectionalLightDirections = new Vector4[MaxDirectionalLightCount];

        private static readonly int AdditionalDirectionalLightCountId = Shader.PropertyToID("_AdditionalDirectionalLightCount");
        private static readonly int AdditionalDirectionalLightColorsId = Shader.PropertyToID("_AdditionalDirectionalLightColors");
        private static readonly int AdditionalDirectionalLightDirectionsId =
            Shader.PropertyToID("_AdditionalDirectionalLightDirections");
        
        private readonly CommandBuffer _buffer = new CommandBuffer()
        {
            name = BufferName
        };
        
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
        /// シーン中のライト情報を設定する
        /// </summary>
        private void SetupLights()
        {
            var visibleLights = _cullingResults.visibleLights;
            var additionalDirectionalLightCount = 0;
            for (var i = 0; i < visibleLights.Length; i++)
            {
                var visibleLight = visibleLights[i];
                if (visibleLight.lightType == LightType.Directional)
                {
                    if (visibleLight.light == RenderSettings.sun)
                    {
                        // サンライトは別枠で計算してあるので除外
                        continue;
                    }
                    SetupDirectionalLight(additionalDirectionalLightCount++, ref visibleLight);
                    if (additionalDirectionalLightCount>= MaxDirectionalLightCount)
                    {
                        break;
                    }
                }
            }

            // 求めたライト情報をシェーダに送る
            _buffer.SetGlobalInt(AdditionalDirectionalLightCountId, additionalDirectionalLightCount);
            _buffer.SetGlobalVectorArray(AdditionalDirectionalLightColorsId, DirectionalLightColors);
            _buffer.SetGlobalVectorArray(AdditionalDirectionalLightDirectionsId, DirectionalLightDirections);
        }

        private static void SetupDirectionalLight(int index, ref VisibleLight visibleLight)
        {
            DirectionalLightColors[index] = visibleLight.light.color;
            DirectionalLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        }
    }
}