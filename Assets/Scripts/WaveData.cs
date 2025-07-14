using UnityEngine;

// WaveData.cs - ScriptableObject for wave configuration (with spawnPoints field added/fixed)
[CreateAssetMenu(fileName = "WaveData", menuName = "WaveSystem/WaveData", order = 1)]
public class WaveData : ScriptableObject
{
    public int baseEnemyCount = 2; // Starting number of enemies per wave
    public float enemyCountMultiplier = 1.2f; // Multiplicative increase per wave
    public float enemyHealthMultiplier = 1.1f; // Scales enemy health
    public float enemySpeedMultiplier = 1.05f; // Scales enemy speed
    public float waveInterval = 30f; // Time between waves in seconds
    public GameObject[] enemyPrefabs; // Array of regular enemy prefabs
    public GameObject[] bossPrefabs; // Array of boss prefabs for random selection

    // Fixed: Public array for spawn points (this resolves the CS1061 errors)
    public Vector3[] spawnPoints; // Array of spawn locations - drag positions or use Inspector to set
}