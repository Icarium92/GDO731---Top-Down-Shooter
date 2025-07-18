using UnityEngine;

public class UI : MonoBehaviour
{
    public static UI instance;

    public UI_InGame inGameUI { get; private set; }

    private void Awake()
    {
        instance = this;
        inGameUI = GetComponentInChildren<UI_InGame>();
    }
}
