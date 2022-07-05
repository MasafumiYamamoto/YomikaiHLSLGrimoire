using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

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
            SetupPerFrameShaderConstants();

            SortCameras(cameras);

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

            // ライト情報の初期化
            var lighting = new GrimoireLight();
            lighting.Setup(context, cullingResults);

            // 現在のカメラに基づいて、ビルトインのシェーダ変数の値を更新
            context.SetupCameraProperties(camera);

            var cmd = CommandBufferPool.Get("Camera Buffer");
            var clearFlag = GetCameraClearFlag(camera);
            CoreUtils.ClearRenderTarget(cmd, clearFlag, camera.backgroundColor);
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

        /// <summary>
        ///     シェーダに依存しないパラメータの設定
        /// </summary>
        private static void SetupPerFrameShaderConstants()
        {
            // 環境光に必要なパラメータ設定
            Shader.SetGlobalColor(Shader.PropertyToID("unity_AmbientSky"), RenderSettings.ambientSkyColor);
            Shader.SetGlobalColor(Shader.PropertyToID("unity_AmbientEquator"), RenderSettings.ambientEquatorColor);
            Shader.SetGlobalColor(Shader.PropertyToID("unity_AmbientGround"), RenderSettings.ambientGroundColor);
        }

        /// <summary>
        ///     UniversalRenderPipeline.GetCameraClearFlag()を参考にしつつ、CameraDataを1から作るのが面倒なのでよしなに処理してしまう
        /// </summary>
        /// <param name="camera"></param>
        /// <returns></returns>
        private ClearFlag GetCameraClearFlag(Camera camera)
        {
            var cameraClearFlags = camera.clearFlags;

            return cameraClearFlags switch
            {
                // XRTODO: remove once we have visible area of occlusion mesh available
                CameraClearFlags.Skybox when RenderSettings.skybox != null => ClearFlag.All,
                CameraClearFlags.Nothing => ClearFlag.DepthStencil,
                _ => ClearFlag.All
            };
        }

        /// <summary>
        ///     CameraからCameraDataの初期化を行う
        /// </summary>
        private static void InitializeCameraData(Camera camera, out CameraData cameraData)
        {
            cameraData = new CameraData();
            cameraData.camera = camera;
        }
    }
}