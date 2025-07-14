using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player_Health : HealthController
{
    public bool isDead { get; private set; }
    private bool isInvincible = false;

    private Player player;

    protected override void Awake()
    {
        base.Awake();
        player = GetComponent<Player>();
    }

    public override void ReduceHealth(int damage)
    {
        if (isInvincible) return;

        base.ReduceHealth(damage);

        // NEW: Update health bar when taking damage (same as enemy approach)
        if (player.healthBar != null)
        {
            player.healthBar.value = currentHealth;
        }

        if (ShouldDie())
            Die();
    }

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