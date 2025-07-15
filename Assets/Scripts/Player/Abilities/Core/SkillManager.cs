using System.Collections.Generic;
using UnityEngine;

public class SkillManager : MonoBehaviour
{
    [Header("Required Reference")]
    [Tooltip("Assign the Player component this skill system controls.")]
    public Player player;

    [Header("Player Abilities")]
    [Tooltip("Assign all AbilityData ScriptableObjects that should be available to this player.")]
    [SerializeField] private AbilityData[] allAbilities;

    [Header("Dash Settings")]
    [Tooltip("Maximum distance the player can dash")]
    public float dashDistance = 2.5f;

    [Tooltip("Speed of the dash movement")]
    public float dashSpeed = 15f;

    [Tooltip("Cooldown time between dash uses (in seconds)")]
    public float dashCooldown = 1.5f;

    [Tooltip("Layers that block dash movement")]
    public LayerMask dashObstacles = -1;

    private readonly Dictionary<AbilityType, IAbility> abilities = new();

    private void Awake()
    {
        if (player == null)
        {
            Debug.LogError("SkillManager: Player reference is not assigned. Please assign it in the Inspector.");
            return;
        }
    }

    private void Start()
    {
        InitializeAbilities();
    }

    private void InitializeAbilities()
    {
        abilities.Clear();

        foreach (var data in allAbilities)
        {
            if (data == null)
            {
                Debug.LogWarning("SkillManager: A null AbilityData was found in the allAbilities list.");
                continue;
            }

            if (abilities.ContainsKey(data.type))
            {
                Debug.LogWarning($"SkillManager: Duplicate ability type '{data.type}' found. Skipping duplicate.");
                continue;
            }

            IAbility ability = CreateAbility(data);
            if (ability != null)
            {
                abilities[data.type] = ability;
                Debug.Log($"SkillManager: Successfully created ability '{data.type}'");
            }
            else
            {
                Debug.LogWarning($"SkillManager: Could not create an ability for type '{data.type}'.");
            }
        }
    }

    private IAbility CreateAbility(AbilityData data)
    {
        switch (data.type)
        {
            case AbilityType.Dash:
                Debug.Log("Creating DashAbility");
                return new DashAbility(data, player, this);

            default:
                Debug.LogWarning($"SkillManager: No case found for AbilityType '{data.type}'.");
                return null;
        }
    }

    public bool TryActivateAbility(AbilityType type)
    {
        if (abilities.TryGetValue(type, out var ability))
        {
            if (ability.CanActivate())
            {
                ability.Activate();
                return true;
            }
            else
            {
                Debug.Log($"SkillManager: Ability '{type}' cannot be activated right now. Cooldown: {ability.CooldownProgress:F1}");
            }
        }
        else
        {
            Debug.LogWarning($"SkillManager: Ability '{type}' not found.");
        }

        return false;
    }

    public IAbility GetAbility(AbilityType type)
    {
        abilities.TryGetValue(type, out var ability);
        return ability;
    }

    public float GetDashCooldownProgress()
    {
        if (abilities.TryGetValue(AbilityType.Dash, out var ability))
        {
            return ability.CooldownProgress;
        }
        return 1f; // Ready
    }

    private void Update()
    {
        foreach (var ability in abilities.Values)
        {
            ability.Update();
        }

        HandleInput();
    }

    private void HandleInput()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Debug.Log("Space key pressed - attempting dash");
            TryActivateAbility(AbilityType.Dash);
        }

        if (Input.GetKeyDown(KeyCode.G))
        {
            TryActivateAbility(AbilityType.Grenade);
        }
    }
}