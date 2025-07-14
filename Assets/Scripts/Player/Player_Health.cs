using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player_Health : HealthController
{
    private Player player;

    public bool isDead { get; private set; }
    private bool isInvincible = false; // NEW: For ability system integration

    protected override void Awake()
    {
        base.Awake();

        player = GetComponent<Player>();
    }

    public override void ReduceHealth(int damage)
    {
        if (isInvincible) return; // NEW: Ability system integration

        base.ReduceHealth(damage);

        if (ShouldDie())
            Die();
    }

    // NEW: Method for ability system integration
    public void SetInvincible(bool invincible)
    {
        isInvincible = invincible;
    }

    private void Die()
    {
        if (isDead)
            return;

        Debug.Log("Player was killed at " + Time.time);
        isDead = true;
        player.anim.enabled = false;
        player.ragdoll.RagdollActive(true);
    }
}