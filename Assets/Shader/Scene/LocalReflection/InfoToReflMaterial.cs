using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class InfoToReflMaterial : MonoBehaviour
{
	// The proxy volume used for local reflection calculations.
	public GameObject boundingBox;
	void Start()
	{
		Vector3 bboxLength = boundingBox.transform.localScale;
		Vector3 centerBBox = boundingBox.transform.position;
		// Min and max BBox points in world coordinates
		Vector3 BMin = centerBBox - bboxLength/2;
		Vector3 BMax = centerBBox + bboxLength/2;
		// Pass the values to the material.
		gameObject.GetComponent<Renderer>().sharedMaterial.SetVector("_BBoxMin", BMin);
		gameObject.GetComponent<Renderer>().sharedMaterial.SetVector("_BBoxMax", BMax);
		gameObject.GetComponent<Renderer>().sharedMaterial.SetVector("_EnviCubeMapPos", centerBBox);
	}
}
