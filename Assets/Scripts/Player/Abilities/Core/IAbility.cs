using UnityEngine;

public interface IAbility
{
    // Properties
    AbilityData Data { get; }
    AbilityState State { get; }
    float CooldownProgress { get; }
    bool IsOnCooldown { get; }
    bool IsActive { get; }

    // Core activation methods
    bool CanActivate();
    void Activate();
    bool TryActivate();
    void CompleteAbility();
    void Update();
    void Cancel();
    void Reset();
    void ResetCooldown();

    // Progress tracking
    float GetCooldownProgress();
}