using UnityEngine;

// GameManager.cs - Singleton with added friendlyFire toggle
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; } // Singleton pattern (capital 'I')

    [SerializeField] public WaveManager waveManager; // Existing reference
    [SerializeField] public bool friendlyFire = false; // New: Toggle for friendly fire - why? Allows runtime config without code changes

    // Your existing settings (e.g., currentScore)
    public int currentScore = 0;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    // Add other methods as needed
}