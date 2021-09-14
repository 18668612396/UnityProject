using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class SceneParam : MonoBehaviour
{
    [Range(0.0f, 1.0f)]
    public float test = 0.0f;

    private void Update()
    {
        transform.Rotate(Vector3.left, 10 * Time.deltaTime, Space.World);
        Shader.SetGlobalFloat("_test", test);
    }
}
