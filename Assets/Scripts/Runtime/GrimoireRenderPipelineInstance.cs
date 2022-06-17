using UnityEngine;
using UnityEngine.Rendering;

namespace Runtime
{
    /// <summary>
    /// レンダーパイプラインインスタンスの定義
    /// ここでカスタムのレンダリングコードを記述する
    /// </summary>
    public class GrimoireRenderPipelineInstance : RenderPipeline
    {
        public GrimoireRenderPipelineInstance()
        {
        }
        
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            // すべてのカメラに対して繰り返し実行
            foreach (var camera in cameras)
            {
                // 試用しているカメラからカリングパラメータを取得
                camera.TryGetCullingParameters(out var cullingParameters);
                
                // カリングパラメータを使ってカリング操作を行い、結果を保存
                var cullingResults = context.Cull(ref cullingParameters);

                // 現在のカメラに基づいて、ビルトインのシェーダ変数の値を更新
                context.SetupCameraProperties(camera);
                
                // 現在のレンダーターゲットを消去するコマンドを作成してスケジューリングします
                ClearRenderTarget(context, camera);
                
                // ライトの設定
                SetLightShaderParam(context, ref cullingResults);

                // LightModeパスタグの値を利用して、Unityに描画するジオメトリを支持する
                var shaderTagId = new ShaderTagId("ExampleLightModeTag");
                
                // 現在のカメラに基づいて、Unityにジオメトリを並び替える方法を指示
                var sortingSettings = new SortingSettings(camera);
                
                // どのジオメトリを描画するかとその描画方法を説明するDrawingSettings構造体の作成
                var drawingSettings = new DrawingSettings(shaderTagId, sortingSettings);
                
                // カリング結果をフィルタリングする方法をUnityに指示し描画するジオメトリの指定
                // FilterSettings.defaultValueだとフィルタリングなしになる
                var filteringSettings = FilteringSettings.defaultValue;

                // 定義した設定に基づいてジオメトリを描画するコマンドをスケジューリング
                context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
                
                // 必要に応じてスカイボックスも描画
                if (camera.clearFlags == CameraClearFlags.Skybox && RenderSettings.skybox != null)
                {
                    context.DrawSkybox(camera);
                }
            }

            // スケジュールされたすべてのコマンドを実行するようにグラフィックスAPIに指示
            context.Submit();
        }

        private void ClearRenderTarget(ScriptableRenderContext context, Camera camera)
        {
            var cmd = CommandBufferPool.Get();
            var clearFlags = camera.clearFlags;
            cmd.ClearRenderTarget((clearFlags & CameraClearFlags.Depth) != 0, (clearFlags & CameraClearFlags.Color) != 0, camera.backgroundColor);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        private void SetLightShaderParam(ScriptableRenderContext context, ref CullingResults cullingResults)
        {
            foreach (var light in cullingResults.visibleLights)
            {
                if (light.lightType == LightType.Directional)
                {
                    var mainLight = light.light;
                    var cmd = CommandBufferPool.Get();
                    cmd.SetGlobalVector(Shader.PropertyToID("_LightDirection"), mainLight.transform.forward.normalized);
                    cmd.SetGlobalVector(Shader.PropertyToID("_LightColor"), mainLight.color);
                    context.ExecuteCommandBuffer(cmd);
                    CommandBufferPool.Release(cmd);
                    return;
                }
                if (light.lightType == LightType.Point)
                {
                    var mainLight = light.light;
                    var cmd = CommandBufferPool.Get();
                    cmd.SetGlobalVector(Shader.PropertyToID("_LightPosition"), mainLight.transform.position);
                    cmd.SetGlobalVector(Shader.PropertyToID("_LightColor"), mainLight.color);
                    cmd.SetGlobalFloat(Shader.PropertyToID("_LightRange"), mainLight.range);
                    context.ExecuteCommandBuffer(cmd);
                    CommandBufferPool.Release(cmd);
                }
            }
        }
    }
}