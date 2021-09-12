using UnityEngine;
using UnityEditor;
using System.Collections;
public class Gatu_VertexPainter_Window : EditorWindow
{
    #region  Varialbes
    #endregion

    #region Main Method
    public static void LaunchVertexPainter()
    {
        var window = EditorWindow.GetWindow<Gatu_VertexPainter_Window>(false, "VTX Painter", true);
    }

    void OnEnable()
    {

    }

    void OnDestroy()
    {

    }
    #endregion

    #region GUI Methods

    void OnGUI()
    {
        GUILayout.Button("button");
        Repaint();
    }


    #endregion

    #region Utility Methods
    #endregion
}
