using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;

// EnemyPool.cs - Fixed to prevent early spawns with delayed init and strict deactivation
public class EnemyPool : MonoBehaviour
{
    [SerializeField] private GameObject[] enemyPrefabs; // Drag your enemy and boss prefabs here
    [SerializeField] private int initialPoolSize = 10; // Starting instances per prefab
    [SerializeField] private int maxPoolSize = 50; // Max per prefab

    private Dictionary<GameObject, ObjectPool<GameObject>> pools = new Dictionary<GameObject, ObjectPool<GameObject>>();

    private void Start()
    {
        StartCoroutine(InitializePoolsDelayed()); // Delayed init - why? Prevents startup ghost spawns by waiting one frame
    }

    private IEnumerator InitializePoolsDelayed()
    {
        yield return null; // Wait one frame for scene stability

        if (enemyPrefabs == null || enemyPrefabs.Length == 0)
        {
            Debug.LogWarning("No prefabs assigned to EnemyPool - assign in Inspector!");
            yield break;
        }

        foreach (var prefab in enemyPrefabs)
        {
            if (prefab == null) continue;

            var pool = new ObjectPool<GameObject>(
                () => CreateEnemy(prefab),
                OnGetEnemy,
                OnReleaseEnemy,
                OnDestroyEnemy,
                true, initialPoolSize, maxPoolSize
            );
            pools[prefab] = pool;
        }

        Debug.Log("EnemyPool: Pools initialized successfully");
    }

    public GameObject Get(GameObject prefab)
    {
        if (!pools.ContainsKey(prefab))
        {
            Debug.LogWarning($"No pool for {prefab.name} - Creating on the fly");
            var pool = new ObjectPool<GameObject>(
                () => CreateEnemy(prefab),
                OnGetEnemy,
                OnReleaseEnemy,
                OnDestroyEnemy,
                true, initialPoolSize, maxPoolSize
            );
            pools[prefab] = pool;
        }
        return pools[prefab].Get();
    }

    public void Release(GameObject enemy, GameObject prefab)
    {
        if (pools.ContainsKey(prefab))
        {
            pools[prefab].Release(enemy);
        }
        else
        {
            Debug.LogWarning($"No pool found for releasing {enemy.name} - destroying instead");
            Destroy(enemy);
        }
    }

    private GameObject CreateEnemy(GameObject prefab)
    {
        GameObject enemy = Instantiate(prefab, Vector3.zero, Quaternion.identity);
        enemy.SetActive(false); // Ensure deactivated on creation
        enemy.transform.SetParent(null); // No parent to avoid Hierarchy visibility
        Debug.Log($"Created pooled enemy: {prefab.name} (inactive)"); // Temp log for debugging
        return enemy;
    }

    private void OnGetEnemy(GameObject enemy)
    {
        enemy.SetActive(true);
        Debug.Log($"Activated enemy: {enemy.name}"); // Temp log to track activations
    }

    private void OnReleaseEnemy(GameObject enemy)
    {
        enemy.SetActive(false);
        enemy.transform.SetParent(null); // Reset parent on release
        Debug.Log($"Deactivated and released enemy: {enemy.name}"); // Temp log
    }

    private void OnDestroyEnemy(GameObject enemy)
    {
        Destroy(enemy);
    }
}
