using UnityEngine;
using UnityEngine.Rendering;

namespace Runtime
{
    /// <summary>
    ///     レンダーパイプラインインスタンスの定義
    ///     ここでカスタムのレンダリングコードを記述する
    /// </summary>
    public class GrimoireRenderPipelineInstance : RenderPipeline
    {
        private readonly CommandBuffer _cameraBuffer = new()
        {
            name = "Render Camera"
        };

        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            // すべてのカメラに対して繰り返し実行
            foreach (var camera in cameras) Render(context, camera);
        }

        private void Render(ScriptableRenderContext context, Camera camera)
        {
            // 試用しているカメラからカリングパラメータを取得
            camera.TryGetCullingParameters(out var cullingParameters);

            // カリングパラメータを使ってカリング操作を行い、結果を保存
            var cullingResults = context.Cull(ref cullingParameters);

            // 現在のカメラに基づいて、ビルトインのシェーダ変数の値を更新
            context.SetupCameraProperties(camera);

            var clearFlags = camera.clearFlags;
            _cameraBuffer.ClearRenderTarget((clearFlags & CameraClearFlags.Depth) != 0,
                (clearFlags & CameraClearFlags.Color) != 0,
                camera.backgroundColor);
            context.ExecuteCommandBuffer(_cameraBuffer);
            _cameraBuffer.Clear();

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
                context.DrawSkybox(camera);


            // スケジュールされたすべてのコマンドを実行するようにグラフィックスAPIに指示
            context.Submit();
        }
    }
}