using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;

public class RuntimeManager : MonoBehaviour
{

    public UnityEvent OnStageClear;
    public UnityEvent OnGamePause;
    public static bool IsPaused;

    public void OnPauseGame(InputAction.CallbackContext context)
    {
        if (context.performed)
        {
            PauseGame();
            OnGamePause?.Invoke();
        }
    }

    private void Awake()
    {
        IsPaused = false;
    }

    private IEnumerator EndStage()
    {
        yield return new WaitForSeconds(1f);
        OnStageClear?.Invoke();
    }

    public void PauseGame()
    {
        Time.timeScale = 0;
        IsPaused = true;
    }

    public void ResumeGame()
    {
        Time.timeScale = 1;
        IsPaused = false;
    }

    public void QuitGame()
    {
        Application.Quit();
    }
}

