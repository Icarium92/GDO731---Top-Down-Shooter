using UnityEngine;
using System.Collections;

public abstract class BaseAbility : IAbility
{
    public AbilityData Data { get; private set; }
    public AbilityState State { get; protected set; }
    public float CooldownProgress => 1f - (cooldownTimer / Data.cooldown);

    protected Player player;
    protected float cooldownTimer;
    protected float durationTimer;
    protected bool isOnCooldown;

    public BaseAbility(AbilityData data, Player player)
    {
        this.Data = data;
        this.player = player;
        State = AbilityState.Ready;
    }

    public virtual bool CanActivate()
    {
        bool stateReady = State == AbilityState.Ready;
        bool notOnCooldown = !isOnCooldown;
        bool hasResources = HasRequiredResources();
        bool meetsConditions = MeetsActivationConditions();

        Debug.Log($"BaseAbility CanActivate - State: {State}, OnCooldown: {isOnCooldown}, HasResources: {hasResources}, MeetsConditions: {meetsConditions}");

        return stateReady && notOnCooldown && hasResources && meetsConditions;
    }

    public virtual void Activate()
    {
        if (!CanActivate())
        {
            Debug.Log($"BaseAbility: Cannot activate {GetType().Name}");
            return;
        }

        Debug.Log($"BaseAbility: Activating {GetType().Name}");
        State = AbilityState.Activating;
        ConsumeResources();
        PlayActivationEffects();

        if (Data.castTime > 0)
        {
            player.StartCoroutine(CastTimeCoroutine());
        }
        else
        {
            ExecuteAbility();
        }
    }

    public virtual void Update()
    {
        HandleCooldown();
        HandleDuration();
        UpdateAbilityLogic();
    }

    public virtual void Cancel()
    {
        if (State == AbilityState.Activating || State == AbilityState.Active)
        {
            State = AbilityState.Ready;
            OnAbilityCancel();
        }
    }

    public virtual void Reset()
    {
        State = AbilityState.Ready;
        cooldownTimer = 0f;
        durationTimer = 0f;
        isOnCooldown = false;
        OnAbilityReset();
    }

    protected virtual bool HasRequiredResources()
    {
        return true;
    }

    protected virtual bool MeetsActivationConditions()
    {
        return true;
    }

    protected virtual void ConsumeResources()
    {
        // Override in derived classes for resource consumption
    }

    protected virtual void PlayActivationEffects()
    {
        if (Data.activationEffectPrefab != null)
        {
            GameObject effect = ObjectPool.instance.GetObject(Data.activationEffectPrefab, player.transform);
            ObjectPool.instance.ReturnObject(effect, 1f);
        }

        if (Data.activationSound != null)
        {
            // Play sound - integrate with your audio system
        }
    }

    protected virtual IEnumerator CastTimeCoroutine()
    {
        float castTimer = 0f;
        while (castTimer < Data.castTime)
        {
            castTimer += Time.deltaTime;
            OnCastTimeUpdate(castTimer / Data.castTime);
            yield return null;
        }

        ExecuteAbility();
    }

    protected virtual void ExecuteAbility()
    {
        State = AbilityState.Active;
        durationTimer = Data.duration;
        OnAbilityExecute();

        if (Data.duration <= 0)
        {
            CompleteAbility();
        }
    }

    protected virtual void CompleteAbility()
    {
        State = AbilityState.Cooldown;
        cooldownTimer = Data.cooldown;
        isOnCooldown = true;
        OnAbilityComplete();
    }

    private void HandleCooldown()
    {
        if (isOnCooldown)
        {
            cooldownTimer -= Time.deltaTime;
            if (cooldownTimer <= 0)
            {
                isOnCooldown = false;
                State = AbilityState.Ready;
            }
        }
    }

    private void HandleDuration()
    {
        if (State == AbilityState.Active && Data.duration > 0)
        {
            durationTimer -= Time.deltaTime;
            if (durationTimer <= 0)
            {
                CompleteAbility();
            }
        }
    }

    // Abstract methods for derived classes
    protected abstract void UpdateAbilityLogic();
    protected abstract void OnAbilityExecute();
    protected abstract void OnAbilityComplete();

    // Virtual methods for optional overrides
    protected virtual void OnAbilityCancel() { }
    protected virtual void OnAbilityReset() { }
    protected virtual void OnCastTimeUpdate(float progress) { }
}