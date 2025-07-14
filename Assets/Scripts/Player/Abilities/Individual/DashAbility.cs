using UnityEngine;
using System.Collections;

public class DashAbility : BaseAbility
{
    [Header("Dash Settings")]
    private float dashDistance = 2.5f;
    private float dashSpeed = 15f;
    private LayerMask obstacles = -1;

    private CharacterController characterController;
    private Player_Movement movement;
    private Player_Health health;
    private Vector3 dashDirection;
    private bool isDashing;
    private float currentDashDistance;

    // Dynamic effect references
    private GameObject activeTrailEffect;
    private GameObject activeParticleEffect;
    private string abilityId;

    public DashAbility(AbilityData data, Player player) : base(data, player)
    {
        characterController = player.GetComponent<CharacterController>();
        movement = player.movement;
        health = player.health;

        // Create unique ability ID for effect tracking
        abilityId = $"Dash_{player.GetInstanceID()}";
    }

    protected override bool MeetsActivationConditions()
    {
        return !isDashing &&
               health != null && !health.isDead &&
               movement != null &&
               characterController != null;
    }

    protected override void OnAbilityExecute()
    {
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
        Vector3 inputDirection = new Vector3(
            movement.moveInput.x,
            0,
            movement.moveInput.y
        ).normalized;

        dashDirection = inputDirection != Vector3.zero ? inputDirection : player.transform.forward;
    }

    private void CalculateActualDashDistance()
    {
        currentDashDistance = dashDistance;

        if (Physics.Raycast(player.transform.position, dashDirection, dashDistance, obstacles))
        {
            RaycastHit hit;
            Physics.Raycast(player.transform.position, dashDirection, out hit, dashDistance, obstacles);
            currentDashDistance = Mathf.Max(hit.distance - 0.5f, 1f);
        }
    }

    private void EnableEffects()
    {
        // Spawn trail effect
        if (Data.trailEffectPrefab != null)
        {
            activeTrailEffect = AbilityEffectManager.Instance.SpawnEffect(
                Data.trailEffectPrefab,
                player.transform,
                abilityId
            );
        }

        // Spawn particle effect
        if (Data.particleEffectPrefab != null)
        {
            activeParticleEffect = AbilityEffectManager.Instance.SpawnEffect(
                Data.particleEffectPrefab,
                player.transform,
                abilityId
            );
        }

        // Play activation effect
        if (Data.activationEffectPrefab != null)
        {
            GameObject activationEffect = AbilityEffectManager.Instance.SpawnEffect(
                Data.activationEffectPrefab,
                player.transform,
                abilityId
            );

            // Auto-destroy activation effect after short time
            player.StartCoroutine(DestroyEffectDelayed(activationEffect, 1f));
        }

        // Play sound effect
        if (Data.activationSound != null)
        {
            AudioSource.PlayClipAtPoint(Data.activationSound, player.transform.position);
        }
    }

    private void DisableEffects()
    {
        // Destroy trail effect with delay for natural fade
        if (activeTrailEffect != null)
        {
            player.StartCoroutine(DestroyEffectDelayed(activeTrailEffect, 0.5f));
        }

        // Stop and destroy particle effect
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
        AbilityEffectManager.Instance.DestroyEffect(effect, abilityId);
    }

    private IEnumerator PerformDash()
    {
        isDashing = true;

        // Disable movement and enable invincibility
        if (movement != null)
            movement.SetMovementEnabled(false);
        if (health != null)
            health.SetInvincible(true);

        // Enable visual effects
        EnableEffects();

        Vector3 startPosition = player.transform.position;
        Vector3 targetPosition = startPosition + (dashDirection * currentDashDistance);

        float dashTime = currentDashDistance / dashSpeed;
        float elapsedTime = 0f;

        while (elapsedTime < dashTime)
        {
            elapsedTime += Time.deltaTime;
            Vector3 frameMovement = dashDirection * dashSpeed * Time.deltaTime;
            characterController.Move(frameMovement);
            yield return null;
        }

        CompleteAbility();
    }
}