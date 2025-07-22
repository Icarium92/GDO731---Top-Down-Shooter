using UnityEngine;

[System.Serializable]
public enum AbilityType
{
    Dash,
    Grenade,
    Trap,
    HeavyAttack
}

[System.Serializable]
public enum AbilityState
{
    Ready,
    Activating,
    Active,
    Completing,
    Cooldown,
    Cancelled
}