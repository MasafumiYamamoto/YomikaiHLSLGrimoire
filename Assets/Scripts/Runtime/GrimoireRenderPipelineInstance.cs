using System;
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
        /// <summary>
        ///     カメラをdepthの値を利用してソートする
        /// </summary>
        /// <param name="cameras"></param>
        private void SortCameras(Camera[] cameras)
        {
            Array.Sort(cameras, (lhs, rhs) => (int)(lhs.depth - rhs.depth));
        }

        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            // パイプラインに登録されている前処理
            BeginFrameRendering(context, cameras);
            GraphicsSettings.lightsUseLinearIntensity = QualitySettings.activeColorSpace == ColorSpace.Linear;

            // すべてのカメラに対して繰り返し実行
            foreach (var camera in cameras) Render(context, camera);

            // フレームの後処理デリゲートの実行
            EndFrameRendering(context, cameras);
        }

        private void Render(ScriptableRenderContext context, Camera camera)
        {
            // パイプラインに登録されている前処理の呼び出し
            BeginCameraRendering(context, camera);

            // 試用しているカメラからカリングパラメータを取得
            if (!camera.TryGetCullingParameters(out var cullingParameters))
                // カリング結果が不適切なら何もしない
                return;

            // カリングパラメータを使ってカリング操作を行い、結果を保存
            var cullingResults = context.Cull(ref cullingParameters);

            // 現在のカメラに基づいて、ビルトインのシェーダ変数の値を更新
            context.SetupCameraProperties(camera);

            var clearFlags = camera.clearFlags;
            var cmd = CommandBufferPool.Get("Camera Buffer");
            cmd.ClearRenderTarget((clearFlags & CameraClearFlags.Depth) != 0,
                (clearFlags & CameraClearFlags.Color) != 0,
                camera.backgroundColor);
            context.ExecuteCommandBuffer(cmd);
            cmd.Release();

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

            EndCameraRendering(context, camera);
        }
    }
}