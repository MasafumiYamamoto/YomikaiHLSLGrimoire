using UnityEngine;
using UnityEngine.Rendering;

namespace Runtime
{
    /// <summary>
    /// レンダーパイプラインアセットの定義
    /// </summary>
    [CreateAssetMenu(menuName = "Rendering/GrimoirePipelineAsset")]
    public class GrimoireRenderPipelineAsset : RenderPipelineAsset
    {
        /// <summary>
        /// 最初のフレームをレンダリングする前に、Unityによってこのメソッドが呼び出される
        /// レンダーパイプラインアセットの設定が変更された場合はUnityは現在のレンダーパイプラインインスタンスを破棄し、次のフレームをレンダリングする前に再度このメソッドを呼び出す
        /// </summary>
        /// <returns></returns>
        protected override RenderPipeline CreatePipeline()
        {
            // このSRPがレンダリングのために使うレンダーパイプラインをインスタンス化する
            return new GrimoireRenderPipelineInstance();
        }
    }
}