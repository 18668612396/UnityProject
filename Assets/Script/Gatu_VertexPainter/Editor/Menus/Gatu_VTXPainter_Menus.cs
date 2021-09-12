using UnityEditor;
using UnityEngine;

public class Gatu_Vtex_Menus : MonoBehaviour
{
    [MenuItem("Gatu/VertexPainter",false,10)]
    static void LaunchSomething()
    {
        Gatu_VertexPainter_Window.LaunchVertexPainter();
    }
}
 
