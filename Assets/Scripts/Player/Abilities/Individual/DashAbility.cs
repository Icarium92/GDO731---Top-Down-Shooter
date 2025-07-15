using UnityEngine;
using System.Collections;

public class DashAbility : BaseAbility
{
    private CharacterController characterController;
    private Player_Movement movement;
    private Player_Health health;
    private Vector3 dashDirection;
    private bool isDashing;
    private float currentDashDistance;
    private SkillManager skillManager;

    // Dynamic effect references
    private GameObject activeTrailEffect;
    private GameObject activeParticleEffect;
    private string abilityId;

    public DashAbility(AbilityData data, Player player, SkillManager skillManager) : base(data, player)
    {
        this.skillManager = skillManager;

        // Override the cooldown from AbilityData with SkillManager's setting
        this.Data.cooldown = skillManager.dashCooldown;

        characterController = player.GetComponent<CharacterController>();
        movement = player.movement ?? player.GetComponent<Player_Movement>();
        health = player.health ?? player.GetComponent<Player_Health>();
        abilityId = $"Dash_{player.GetInstanceID()}";

        Debug.Log($"DashAbility created - Distance: {skillManager.dashDistance}, Speed: {skillManager.dashSpeed}, Cooldown: {skillManager.dashCooldown}");

        if (movement == null) Debug.LogError("DashAbility: Could not find Player_Movement component!");
        if (health == null) Debug.LogError("DashAbility: Could not find Player_Health component!");
    }

    protected override void CompleteAbility()
    {
        // Update cooldown from SkillManager in case it was changed during gameplay
        Data.cooldown = skillManager.dashCooldown;

        // Call base implementation to start cooldown
        base.CompleteAbility();

        Debug.Log($"Dash completed! Cooldown started: {Data.cooldown}s");
    }

    public override bool CanActivate()
    {
        var baseCanActivate = base.CanActivate();
        var customConditions = MeetsActivationConditions();

        return baseCanActivate && customConditions;
    }

    protected override bool MeetsActivationConditions()
    {
        bool notDashing = !isDashing;
        bool healthOk = health != null && !health.isDead;
        bool movementOk = movement != null;
        bool controllerOk = characterController != null;

        return notDashing && healthOk && movementOk && controllerOk;
    }

    protected override void OnAbilityExecute()
    {
        Debug.Log("Executing Dash Ability!");
        CalculateDashDirection();
        CalculateActualDashDistance();
        player.StartCoroutine(PerformDash());
    }

    protected override void UpdateAbilityLogic()
    {
        // Dash logic is handled in coroutine
    }

    protected override void OnAbilityComplete()
    {
        Debug.Log("Dash completed!");
        isDashing = false;

        // Re-enable movement
        if (movement != null)
            movement.SetMovementEnabled(true);

        // Disable invincibility
        if (health != null)
            health.SetInvincible(false);

        // Clean up effects
        DisableEffects();
    }

    private void CalculateDashDirection()
    {
        Vector3 inputDirection = Vector3.zero;

        if (movement != null && movement.moveInput != Vector2.zero)
        {
            inputDirection = new Vector3(
                movement.moveInput.x,
                0,
                movement.moveInput.y
            ).normalized;
        }

        dashDirection = inputDirection != Vector3.zero ? inputDirection : player.transform.forward;
    }

    private void CalculateActualDashDistance()
    {
        currentDashDistance = skillManager.dashDistance;

        if (Physics.Raycast(player.transform.position, dashDirection, skillManager.dashDistance, skillManager.dashObstacles))
        {
            RaycastHit hit;
            Physics.Raycast(player.transform.position, dashDirection, out hit, skillManager.dashDistance, skillManager.dashObstacles);
            currentDashDistance = Mathf.Max(hit.distance - 0.5f, 1f);
        }
    }

    private void EnableEffects()
    {
        if (Data.trailEffectPrefab != null)
        {
            activeTrailEffect = AbilityEffectManager.Instance.SpawnEffect(
                Data.trailEffectPrefab,
                player.transform,
                abilityId
            );
        }

        if (Data.particleEffectPrefab != null)
        {
            activeParticleEffect = AbilityEffectManager.Instance.SpawnEffect(
                Data.particleEffectPrefab,
                player.transform,
                abilityId
            );
        }

        if (Data.activationEffectPrefab != null)
        {
            GameObject activationEffect = AbilityEffectManager.Instance.SpawnEffect(
                Data.activationEffectPrefab,
                player.transform,
                abilityId
            );

            player.StartCoroutine(DestroyEffectDelayed(activationEffect, 1f));
        }

        if (Data.activationSound != null)
        {
            AudioSource.PlayClipAtPoint(Data.activationSound, player.transform.position);
        }
    }

    private void DisableEffects()
    {
        if (activeTrailEffect != null)
        {
            player.StartCoroutine(DestroyEffectDelayed(activeTrailEffect, 0.5f));
        }

        if (activeParticleEffect != null)
        {
            ParticleSystem particles = activeParticleEffect.GetComponent<ParticleSystem>();
            if (particles != null)
            {
                particles.Stop();
                player.StartCoroutine(DestroyEffectDelayed(activeParticleEffect, 1f));
            }
        }
    }

    private IEnumerator DestroyEffectDelayed(GameObject effect, float delay)
    {
        yield return new WaitForSeconds(delay);
        if (AbilityEffectManager.Instance != null)
        {
            AbilityEffectManager.Instance.DestroyEffect(effect, abilityId);
        }
    }

    private IEnumerator PerformDash()
    {
        isDashing = true;

        if (movement != null)
            movement.SetMovementEnabled(false);
        if (health != null)
            health.SetInvincible(true);

        EnableEffects();

        float dashTime = currentDashDistance / skillManager.dashSpeed;
        float elapsedTime = 0f;

        while (elapsedTime < dashTime)
        {
            elapsedTime += Time.deltaTime;
            Vector3 frameMovement = dashDirection * skillManager.dashSpeed * Time.deltaTime;

            if (characterController != null)
            {
                characterController.Move(frameMovement);
            }
            else
            {
                Debug.LogError("CharacterController is null during dash!");
                break;
            }

            yield return null;
        }

        CompleteAbility();
    }
}