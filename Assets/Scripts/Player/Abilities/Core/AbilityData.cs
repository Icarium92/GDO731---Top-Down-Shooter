using UnityEngine;

[CreateAssetMenu(fileName = "New Ability", menuName = "Abilities/Ability Data")]
public class AbilityData : ScriptableObject
{
    [Header("Basic Info")]
    public string abilityName;
    public string description;
    public AbilityType type;
    public Sprite icon;

    [Header("Timing")]
    public float cooldown = 1f;
    public float duration = 0f;
    public float castTime = 0f;

    [Header("Input")]
    public KeyCode inputKey = KeyCode.Space;

    [Header("Visual Effects")]
    public GameObject trailEffectPrefab;        // NEW: Trail effect prefab
    public GameObject particleEffectPrefab;     // NEW: Particle effect prefab
    public GameObject activationEffectPrefab;   // NEW: Activation effect prefab
    public GameObject ongoingEffectPrefab;      // NEW: Ongoing effect prefab

    [Header("Audio Effects")]
    public AudioClip activationSound;
    public AudioClip ongoingSound;

    [Header("Screen Effects")]
    public bool useScreenShake = false;
    public float shakeIntensity = 0.1f;
    public float shakeDuration = 0.1f;

    [Header("Restrictions")]
    public bool canUseWhileMoving = true;
    public bool canUseWhileAttacking = true;
    public bool interruptsOtherAbilities = false;
}