using UnityEngine;

[System.Serializable]
public enum AbilityType
{
    Dash,
    HeavyAttack,
    Grenade,
    Stealth,
    Ultimate,
    Trap
}

[System.Serializable]
public enum AbilityState
{
    Ready,
    Activating,
    Active,
    Cooldown,
    Disabled
}