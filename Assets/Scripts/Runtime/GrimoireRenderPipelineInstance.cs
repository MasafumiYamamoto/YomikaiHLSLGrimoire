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
            // 現在のレンダーターゲットを消去するコマンドを作成してスケジューリングします
            var cmd = new CommandBuffer();
            cmd.ClearRenderTarget(true, true, Color.cyan);
            context.ExecuteCommandBuffer(cmd);
            cmd.Release();
            
            // すべてのカメラに対して繰り返し実行
            foreach (var camera in cameras)
            {
                // 試用しているカメラからカリングパラメータを取得
                camera.TryGetCullingParameters(out var cullingParameters);
                
                // カリングパラメータを使ってカリング操作を行い、結果を保存
                var cullingResults = context.Cull(ref cullingParameters);
                
                // 現在のカメラに基づいて、ビルトインのシェーダ変数の値を更新
                context.SetupCameraProperties(camera);
                
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
    }
}