using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Player_AbilityController : MonoBehaviour
{
    [Header("Ability Configuration")]
    [SerializeField] private AbilityData[] availableAbilities;

    [Header("Input Settings")]
    [SerializeField] private bool useInputActions = true;

    // Component references
    private Player player;
    private Dictionary<AbilityType, IAbility> abilities;
    private List<IAbility> activeAbilities;

    // Events for UI integration
    public System.Action<AbilityType, float> OnAbilityCooldownUpdate;
    public System.Action<AbilityType, AbilityState> OnAbilityStateChanged;

    public bool HasAbility(AbilityType type) => abilities.ContainsKey(type);
    public IAbility GetAbility(AbilityType type) => abilities.TryGetValue(type, out var ability) ? ability : null;
    public T GetAbility<T>() where T : class, IAbility => abilities.Values.OfType<T>().FirstOrDefault();

    private void Awake()
    {
        player = GetComponent<Player>();
        abilities = new Dictionary<AbilityType, IAbility>();
        activeAbilities = new List<IAbility>();

        // DON'T initialize abilities here - wait for Start()
    }

    private void Start() // MOVED: Initialize abilities in Start() instead of Awake()
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
        foreach (var abilityData in availableAbilities)
        {
            if (abilityData == null) continue;

            IAbility ability = CreateAbility(abilityData);
            if (ability != null)
            {
                abilities[abilityData.type] = ability;
            }
        }
    }

    private IAbility CreateAbility(AbilityData data)
    {
        // Ensure player components are ready
        if (player.movement == null || player.health == null)
        {
            Debug.LogError($"Cannot create {data.type} ability - Player components not ready!");
            return null;
        }

        switch (data.type)
        {
            case AbilityType.Dash:
                return new DashAbility(data, player);
            //case AbilityType.HeavyAttack:
            //    return new HeavyAttackAbility(data, player);
            //case AbilityType.Grenade:
            //    return new GrenadeAbility(data, player);
            // case AbilityType.Stealth:
            //    return new StealthAbility(data, player);
            //case AbilityType.Ultimate:
            //    return new UltimateAbility(data, player);
            //case AbilityType.Trap:
            //    return new TrapAbility(data, player);
            default:
                Debug.LogWarning($"Unknown ability type: {data.type}");
                return null;
        }
    }

    private void HandleInput()
    {
        if (useInputActions)
        {
            HandleInputActions();
        }
        else
        {
            HandleKeyCodeInput();
        }
    }

    private void HandleInputActions()
    {
        // Handle input through Unity's Input System
        if (player.controls.Character.Dash.triggered)
        {
            Debug.Log("Dash input detected!"); // Temporary debug
            bool success = TryActivateAbility(AbilityType.Dash);
            Debug.Log($"Dash activation result: {success}"); // Temporary debug
        }
    }

    private void HandleKeyCodeInput()
    {
        // Fallback to KeyCode input
        foreach (var ability in abilities.Values)
        {
            if (Input.GetKeyDown(ability.Data.inputKey))
            {
                TryActivateAbility(ability.Data.type);
            }
        }
    }

    private void UpdateAbilities()
    {
        foreach (var ability in abilities.Values)
        {
            var previousState = ability.State;
            ability.Update();

            // Notify UI of state changes
            if (previousState != ability.State)
            {
                OnAbilityStateChanged?.Invoke(ability.Data.type, ability.State);
            }

            // Notify UI of cooldown progress
            if (ability.State == AbilityState.Cooldown)
            {
                OnAbilityCooldownUpdate?.Invoke(ability.Data.type, ability.CooldownProgress);
            }
        }
    }

    public bool TryActivateAbility(AbilityType type)
    {
        if (abilities.TryGetValue(type, out var ability))
        {
            if (ability.CanActivate())
            {
                // Check for ability conflicts
                if (ShouldCancelOtherAbilities(ability))
                {
                    CancelConflictingAbilities(ability);
                }

                ability.Activate();
                return true;
            }
        }
        return false;
    }

    public void CancelAbility(AbilityType type)
    {
        if (abilities.TryGetValue(type, out var ability))
        {
            ability.Cancel();
        }
    }

    public void CancelAllAbilities()
    {
        foreach (var ability in abilities.Values)
        {
            ability.Cancel();
        }
    }

    private bool ShouldCancelOtherAbilities(IAbility newAbility)
    {
        return newAbility.Data.interruptsOtherAbilities;
    }

    private void CancelConflictingAbilities(IAbility newAbility)
    {
        foreach (var ability in abilities.Values)
        {
            if (ability != newAbility &&
                (ability.State == AbilityState.Activating || ability.State == AbilityState.Active))
            {
                ability.Cancel();
            }
        }
    }

    public void ResetAllAbilities()
    {
        foreach (var ability in abilities.Values)
        {
            ability.Reset();
        }
    }
}