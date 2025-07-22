using UnityEngine;
using System.Collections.Generic;
using System.Collections;

public class SkillManager : MonoBehaviour
{
    [Header("Ability Configuration")]
    public List<AbilityData> availableAbilities = new List<AbilityData>();

    [Header("Input Settings")]
    public KeyCode dashKey = KeyCode.Space;
    public KeyCode grenadeKey = KeyCode.G;
    public KeyCode trapKey = KeyCode.T;
    public KeyCode heavyAttackKey = KeyCode.Q;

    [Header("Debug")]
    public bool enableDebugLogs = true;

    private Dictionary<AbilityType, IAbility> equippedAbilities = new Dictionary<AbilityType, IAbility>();
    private Player player;
    private StyleSystem styleSystem;

    public System.Action<AbilityType, bool> OnAbilityStateChanged;
    public System.Action<AbilityType> OnAbilityActivated;
    public System.Action<AbilityType> OnAbilityCooldownStarted;

    private void Awake()
    {
        player = GetComponent<Player>();
        if (player == null)
        {
            Debug.LogError("SkillManager: No Player component found!");
            return;
        }

        styleSystem = player.styleSystem;
        if (styleSystem == null)
        {
            Debug.LogWarning("SkillManager: No StyleSystem found. Adding one...");
            styleSystem = gameObject.AddComponent<StyleSystem>();
        }
    }

    private void Start()
    {
        InitializeAbilities();
    }

    private void Update()
    {
        HandleInput();
        UpdateAbilities();
    }

    private void InitializeAbilities()
    {
        if (availableAbilities == null || availableAbilities.Count == 0)
        {
            Debug.LogWarning("SkillManager: No abilities configured!");
            return;
        }

        foreach (AbilityData abilityData in availableAbilities)
        {
            if (abilityData == null) continue;

            IAbility ability = CreateAbility(abilityData);
            if (ability != null)
            {
                equippedAbilities[abilityData.type] = ability;
                if (enableDebugLogs)
                    Debug.Log($"SkillManager: Initialized {abilityData.type} ability");
            }
        }
    }

    private IAbility CreateAbility(AbilityData data)
    {
        try
        {
            switch (data.type)
            {
                case AbilityType.Dash:
                    return new DashAbility(data, player, this);
                case AbilityType.Grenade:
                    return new GrenadeAbility(data, player);
                case AbilityType.Trap:
                    return new TrapAbility(data, player);
                case AbilityType.HeavyAttack:
                    return new ChargeShotAbility(data, player);
                default:
                    Debug.LogWarning($"SkillManager: No case found for AbilityType {data.type}.");
                    return null;
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"SkillManager: Failed to create {data.type} ability: {e.Message}");
            return null;
        }
    }

    private bool IsPlayerAlive()
    {
        return player != null && player.health != null && player.health.currentHealth > 0;
    }

    private void HandleInput()
    {
        if (player == null || !IsPlayerAlive())
            return;

        if (Input.GetKeyDown(dashKey))
            TryActivateAbility(AbilityType.Dash);

        if (Input.GetKeyDown(grenadeKey))
            TryActivateAbility(AbilityType.Grenade);

        if (Input.GetKeyDown(trapKey))
            TryActivateAbility(AbilityType.Trap);

        if (Input.GetKeyDown(heavyAttackKey))
            TryActivateAbility(AbilityType.HeavyAttack);

        if (Input.GetKeyUp(grenadeKey))
            HandleAbilityRelease(AbilityType.Grenade);

        if (Input.GetKeyUp(trapKey))
            HandleAbilityRelease(AbilityType.Trap);

        if (Input.GetKeyUp(heavyAttackKey))
            HandleAbilityRelease(AbilityType.HeavyAttack);
    }

    private void UpdateAbilities()
    {
        foreach (var ability in equippedAbilities.Values)
        {
            ability?.Update();
        }
    }

    public bool TryActivateAbility(AbilityType abilityType)
    {
        if (!equippedAbilities.TryGetValue(abilityType, out IAbility ability))
        {
            if (enableDebugLogs)
                Debug.Log($"SkillManager: No {abilityType} ability equipped");
            return false;
        }

        if (!ability.CanActivate())
        {
            if (enableDebugLogs)
                Debug.Log($"SkillManager: Cannot activate {abilityType} ability");
            return false;
        }

        bool success = ability.TryActivate();
        if (success)
        {
            OnAbilityActivated?.Invoke(abilityType);
            if (enableDebugLogs)
                Debug.Log($"SkillManager: Activated {abilityType} ability");
        }

        return success;
    }

    private void HandleAbilityRelease(AbilityType abilityType)
    {
        if (equippedAbilities.TryGetValue(abilityType, out IAbility ability))
        {
            switch (abilityType)
            {
                case AbilityType.Grenade:
                    if (ability is GrenadeAbility grenadeAbility && grenadeAbility.IsCharging)
                    {
                        ability.CompleteAbility();
                    }
                    break;

                case AbilityType.Trap:
                    if (ability is TrapAbility trapAbility && trapAbility.IsPlacing)
                    {
                        ability.CompleteAbility();
                    }
                    break;

                case AbilityType.HeavyAttack:
                    if (ability is ChargeShotAbility chargeShotAbility && chargeShotAbility.IsCharging)
                    {
                        ability.CompleteAbility();
                    }
                    break;
            }
        }
    }

    public IAbility GetAbility(AbilityType abilityType)
    {
        equippedAbilities.TryGetValue(abilityType, out IAbility ability);
        return ability;
    }

    public T GetAbility<T>(AbilityType abilityType) where T : class, IAbility
    {
        return GetAbility(abilityType) as T;
    }

    public bool IsAbilityEquipped(AbilityType abilityType)
    {
        return equippedAbilities.ContainsKey(abilityType);
    }

    public bool IsAbilityOnCooldown(AbilityType abilityType)
    {
        var ability = GetAbility(abilityType);
        return ability?.IsOnCooldown ?? false;
    }

    public float GetAbilityCooldownProgress(AbilityType abilityType)
    {
        var ability = GetAbility(abilityType);
        return ability?.GetCooldownProgress() ?? 0f;
    }

    public void RefreshAllAbilities()
    {
        foreach (var ability in equippedAbilities.Values)
        {
            if (ability is GrenadeAbility grenade)
                grenade.RefillGrenades();
            else if (ability is TrapAbility trap)
                trap.RefillTraps();

            ability.ResetCooldown();
        }

        if (enableDebugLogs)
            Debug.Log("SkillManager: All abilities refreshed");
    }

    public void AddAbility(AbilityData abilityData)
    {
        if (abilityData == null)
        {
            Debug.LogError("SkillManager: Cannot add null ability data");
            return;
        }

        IAbility ability = CreateAbility(abilityData);
        if (ability != null)
        {
            equippedAbilities[abilityData.type] = ability;
            if (!availableAbilities.Contains(abilityData))
                availableAbilities.Add(abilityData);

            if (enableDebugLogs)
                Debug.Log($"SkillManager: Added {abilityData.type} ability");
        }
    }

    public void RemoveAbility(AbilityType abilityType)
    {
        if (equippedAbilities.Remove(abilityType))
        {
            if (enableDebugLogs)
                Debug.Log($"SkillManager: Removed {abilityType} ability");
        }
    }

    public void NotifyAbilityStateChanged(AbilityType abilityType, bool isActive)
    {
        OnAbilityStateChanged?.Invoke(abilityType, isActive);
    }

    public void NotifyAbilityCooldownStarted(AbilityType abilityType)
    {
        OnAbilityCooldownStarted?.Invoke(abilityType);
    }

    public AbilityInfo GetAbilityInfo(AbilityType abilityType)
    {
        var ability = GetAbility(abilityType);
        if (ability == null) return null;

        return new AbilityInfo
        {
            type = abilityType,
            isOnCooldown = ability.IsOnCooldown,
            cooldownProgress = ability.GetCooldownProgress(),
            canActivate = ability.CanActivate(),
            isActive = ability.IsActive,
            charges = GetAbilityCharges(abilityType),
            maxCharges = GetAbilityMaxCharges(abilityType)
        };
    }

    private int GetAbilityCharges(AbilityType abilityType)
    {
        switch (abilityType)
        {
            case AbilityType.Grenade:
                return (GetAbility<GrenadeAbility>(abilityType))?.GrenadesRemaining ?? 0;
            case AbilityType.Trap:
                return (GetAbility<TrapAbility>(abilityType))?.TrapsRemaining ?? 0;
            default:
                return 0;
        }
    }

    private int GetAbilityMaxCharges(AbilityType abilityType)
    {
        switch (abilityType)
        {
            case AbilityType.Grenade:
                return 3;
            case AbilityType.Trap:
                return 2;
            default:
                return 1;
        }
    }
}

[System.Serializable]
public class AbilityInfo
{
    public AbilityType type;
    public bool isOnCooldown;
    public float cooldownProgress;
    public bool canActivate;
    public bool isActive;
    public int charges;
    public int maxCharges;
}