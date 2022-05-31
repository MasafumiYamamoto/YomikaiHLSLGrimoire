using System.Collections.Generic;
using UnityEngine;

namespace Runtime
{
    /// <summary>
    ///     自分で三角形メッシュを描画するだけのクラス
    /// </summary>
    public class Triangle : MonoBehaviour
    {
        [SerializeField] private Vector2 size = new(1, 1);
        [SerializeField] private Material material;

        private Mesh _triangleMesh;

        private void Start()
        {
            _triangleMesh = new Mesh();

            UpdateMesh();
        }

        private void Update()
        {
            if (_triangleMesh == null) return;

            Graphics.DrawMesh(_triangleMesh, transform.position, transform.rotation, material, 0);
        }

        private void OnValidate()
        {
            UpdateMesh();
        }

        private void UpdateMesh()
        {
            if (_triangleMesh == null) return;

            _triangleMesh.Clear();
            var vertices = new List<Vector3>
            {
                new(0, 0, 0),
                new(size.x, 0, 0),
                new(size.x / 2, size.y, 0)
            };

            _triangleMesh.SetVertices(vertices);

            var indices = new List<int>
            {
                0, 2, 1
            };

            _triangleMesh.SetTriangles(indices, 0);
        }
    }
}