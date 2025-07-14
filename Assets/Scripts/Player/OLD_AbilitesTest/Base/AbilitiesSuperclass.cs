using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class AbilitiesSuperclass : MonoBehaviour
{
    public string Name;
    public float Cooldown;
    public float CooldownTimer;
    public bool IsOnCooldown;
    public UnityEvent OnFire;

    public int AbilityCountMax;
    public int AbilityCount;
    public bool HasAbilityCount;
}
