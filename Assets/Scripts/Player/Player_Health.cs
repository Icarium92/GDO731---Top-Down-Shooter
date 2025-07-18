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

        // Update the health bar UI
        if (player.healthBar != null)
        {
            player.healthBar.value = currentHealth;
        }

        if (ShouldDie())
            Die();

        UI.instance.inGameUI.UpdateHealthUI(currentHealth, maxHealth);
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

        // Hide the health bar
        if (player.healthBar != null)
            player.healthBar.gameObject.SetActive(false);
    }
}