using System.Collections;
using UnityEngine;
using UnityEngine.Events;

// WaveManager.cs - With startup delay to sync with pool
public class WaveManager : MonoBehaviour
{
    [SerializeField] private WaveData waveData;
    [SerializeField] private EnemyPool enemyPool;
    [SerializeField] private Transform enemyParent;

    public UnityEvent onWaveStart;
    public UnityEvent onBossWarning;

    private int currentWave = 0;
    private int enemiesRemaining = 0;

    private void Start()
    {
        if (waveData == null || enemyPool == null || enemyParent == null)
        {
            Debug.LogError("Missing assignments in WaveManager - check Inspector!");
            return;
        }

        StartCoroutine(StartWavesWithDelay()); // Delay to prevent early sync issues
    }

    private IEnumerator StartWavesWithDelay()
    {
        yield return new WaitForSeconds(1f); // 1-second delay - adjust if needed
        Debug.Log("WaveManager: Starting first wave");
        StartCoroutine(StartNextWave());
    }

    private IEnumerator StartNextWave()
    {
        currentWave++;
        bool isBossWave = currentWave % 5 == 0;
        Debug.Log($"WaveManager: Starting wave {currentWave} (Boss: {isBossWave})");

        if (isBossWave)
        {
            onBossWarning.Invoke();
            yield return new WaitForSeconds(5f);
            SpawnBoss();
        }
        else
        {
            onWaveStart.Invoke();
            SpawnEnemies();
        }

        while (enemiesRemaining > 0)
        {
            yield return null;
        }

        yield return new WaitForSeconds(waveData.waveInterval);
        StartCoroutine(StartNextWave());
    }

    private void SpawnEnemies()
    {
        if (waveData.enemyPrefabs == null || waveData.enemyPrefabs.Length == 0)
        {
            Debug.LogError("No enemy prefabs defined in WaveData!");
            return;
        }

        int enemyCount = (int)(waveData.baseEnemyCount * Mathf.Pow(waveData.enemyCountMultiplier, currentWave - 1));
        enemiesRemaining = enemyCount;
        Debug.Log($"WaveManager: Spawning {enemyCount} enemies for wave {currentWave}");

        for (int i = 0; i < enemyCount; i++)
        {
            GameObject prefab = waveData.enemyPrefabs[Random.Range(0, waveData.enemyPrefabs.Length)];
            if (prefab == null) continue;

            GameObject enemy = enemyPool.Get(prefab);
            if (enemy == null) { Debug.LogError("EnemyPool returned null!"); continue; }

            Vector3 spawnPos = waveData.spawnPoints[Random.Range(0, waveData.spawnPoints.Length)];
            enemy.transform.position = spawnPos;
            enemy.transform.SetParent(enemyParent);
            enemy.SetActive(true);

            Enemy_Health health = enemy.GetComponent<Enemy_Health>();
            if (health != null)
            {
                health.maxHealth = (int)(health.maxHealth * Mathf.Pow(waveData.enemyHealthMultiplier, currentWave - 1));
                health.CurrentHealth = health.maxHealth;
                health.onDeath.AddListener(() => enemiesRemaining--);
            }

            Enemy_Melee ai = enemy.GetComponent<Enemy_Melee>();
            if (ai != null)
            {
                ai.speed *= Mathf.Pow(waveData.enemySpeedMultiplier, currentWave - 1);
            }
        }
    }

    private void SpawnBoss()
    {
        if (waveData.bossPrefabs == null || waveData.bossPrefabs.Length == 0)
        {
            Debug.LogError("No boss prefabs defined in WaveData!");
            return;
        }

        GameObject prefab = waveData.bossPrefabs[Random.Range(0, waveData.bossPrefabs.Length)];
        Debug.Log($"WaveManager: Spawning boss {prefab.name} for wave {currentWave}");

        enemiesRemaining = 1;

        GameObject boss = enemyPool.Get(prefab);
        if (boss == null) { Debug.LogError("EnemyPool returned null for boss!"); return; }

        Vector3 spawnPos = waveData.spawnPoints[Random.Range(0, waveData.spawnPoints.Length)];
        boss.transform.position = spawnPos;
        boss.transform.SetParent(enemyParent);
        boss.SetActive(true);

        Enemy_Health health = boss.GetComponent<Enemy_Health>();
        if (health != null)
        {
            health.maxHealth = (int)(health.maxHealth * Mathf.Pow(waveData.enemyHealthMultiplier, currentWave - 1) * 2f);
            health.CurrentHealth = health.maxHealth;
            health.onDeath.AddListener(() => enemiesRemaining--);
        }

        Enemy_Melee ai = boss.GetComponent<Enemy_Melee>();
        if (ai != null)
        {
            ai.speed *= Mathf.Pow(waveData.enemySpeedMultiplier, currentWave - 1);
        }
    }
}
