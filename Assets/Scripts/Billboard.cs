using UnityEngine;

public class Billboard : MonoBehaviour
{
    void LateUpdate()
    {
        if (Camera.main != null)
        {
            // Make the canvas face the camera
            transform.LookAt(transform.position + Camera.main.transform.forward);
        }
    }
}