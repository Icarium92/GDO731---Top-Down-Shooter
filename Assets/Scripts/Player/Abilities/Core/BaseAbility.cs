using UnityEngine;

public abstract class BaseAbility : IAbility
{
    protected AbilityData data;
    protected Player player;

    protected float cooldownTimer = 0f;
    protected bool isActive = false;
    protected AbilityState currentState = AbilityState.Ready;

    public AbilityData Data => data;
    public AbilityState State => currentState;
    public float CooldownProgress => GetCooldownProgress();
    public bool IsOnCooldown => cooldownTimer > 0f;
    public bool IsActive => isActive;

    public BaseAbility(AbilityData data, Player player)
    {
        this.data = data;
        this.player = player;
    }

    public virtual bool CanActivate()
    {
        return !IsOnCooldown && !IsActive && MeetsActivationConditions();
    }

    public virtual void Activate()
    {
        TryActivate();
    }

    public virtual bool TryActivate()
    {
        if (!CanActivate()) return false;

        isActive = true;
        currentState = AbilityState.Activating;
        OnAbilityExecute();
        currentState = AbilityState.Active;
        return true;
    }

    public virtual void Update()
    {
        if (cooldownTimer > 0f)
        {
            cooldownTimer -= Time.deltaTime;
            if (cooldownTimer <= 0f)
            {
                currentState = AbilityState.Ready;
            }
        }

        if (isActive)
            UpdateAbilityLogic();
    }

    public virtual void CompleteAbility()
    {
        if (isActive)
        {
            currentState = AbilityState.Completing;
            OnAbilityComplete();
            isActive = false;
        }
    }

    public virtual void Cancel()
    {
        if (isActive)
        {
            currentState = AbilityState.Cancelled;
            isActive = false;
        }
    }

    public virtual void Reset()
    {
        isActive = false;
        cooldownTimer = 0f;
        currentState = AbilityState.Ready;
    }

    public void ResetCooldown()
    {
        cooldownTimer = 0f;
        if (currentState == AbilityState.Cooldown)
            currentState = AbilityState.Ready;
    }

    public float GetCooldownProgress()
    {
        if (data == null || data.cooldown <= 0f) return 0f;
        return 1f - (cooldownTimer / data.cooldown);
    }

    protected void StartCooldown()
    {
        if (data != null)
        {
            cooldownTimer = data.cooldown;
            currentState = AbilityState.Cooldown;
        }
    }

    // Abstract methods for subclasses to implement
    protected abstract bool MeetsActivationConditions();
    protected abstract void OnAbilityExecute();
    protected abstract void UpdateAbilityLogic();
    protected abstract void OnAbilityComplete();
}