using UnityEngine;

[CreateAssetMenu(fileName = "New Ability", menuName = "Abilities/Ability Data")]
public class AbilityData : ScriptableObject
{
    [Header("Basic Info")]
    public string abilityName;
    public AbilityType type;
    public float cooldown = 1f;

    [Header("Effects")]
    public GameObject activationEffectPrefab;
    public GameObject particleEffectPrefab;    // Added for dash compatibility
    public GameObject trailEffectPrefab;       // Added for dash compatibility
    public AudioClip activationSound;

    [Header("Description")]
    [TextArea(3, 5)]
    public string description;
}