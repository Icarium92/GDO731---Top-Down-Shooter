using UnityEngine;

public interface IAbility
{
    AbilityData Data { get; }
    AbilityState State { get; }
    float CooldownProgress { get; }
    bool CanActivate();
    void Activate();
    void Update();
    void Cancel();
    void Reset();
}