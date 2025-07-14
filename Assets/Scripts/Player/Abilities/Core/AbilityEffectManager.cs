using UnityEngine;
using System.Collections.Generic;

public class AbilityEffectManager : MonoBehaviour
{
    public static AbilityEffectManager Instance;

    private Dictionary<string, List<GameObject>> activeEffects;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            activeEffects = new Dictionary<string, List<GameObject>>();
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public GameObject SpawnEffect(GameObject effectPrefab, Transform parent, string abilityId)
    {
        if (effectPrefab == null) return null;

        GameObject effect = Instantiate(effectPrefab, parent.position, parent.rotation, parent);

        // Track the effect
        if (!activeEffects.ContainsKey(abilityId))
            activeEffects[abilityId] = new List<GameObject>();

        activeEffects[abilityId].Add(effect);

        return effect;
    }

    public void DestroyEffect(GameObject effect, string abilityId)
    {
        if (effect != null)
        {
            if (activeEffects.ContainsKey(abilityId))
                activeEffects[abilityId].Remove(effect);

            Destroy(effect);
        }
    }

    public void DestroyAllEffects(string abilityId)
    {
        if (activeEffects.ContainsKey(abilityId))
        {
            foreach (var effect in activeEffects[abilityId])
            {
                if (effect != null)
                    Destroy(effect);
            }
            activeEffects[abilityId].Clear();
        }
    }
}