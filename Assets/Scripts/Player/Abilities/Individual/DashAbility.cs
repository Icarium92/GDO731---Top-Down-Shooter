using UnityEngine;
using System.Collections;
using System.Collections.Generic;

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
    private List<ParticleSystem> activeParticleSystems = new List<ParticleSystem>();
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
        // Trail Effect
        if (Data.trailEffectPrefab != null)
        {
            activeTrailEffect = Object.Instantiate(Data.trailEffectPrefab, player.transform);
            activeTrailEffect.transform.localPosition = Vector3.zero;
            activeTrailEffect.transform.localRotation = Quaternion.identity;
        }

        // Particle Effects - collect ALL child particle systems so we can play/stop/manage them
        if (Data.particleEffectPrefab != null)
        {
            activeParticleEffect = Object.Instantiate(Data.particleEffectPrefab, player.transform);
            activeParticleEffect.transform.localPosition = Vector3.zero;
            activeParticleEffect.transform.localRotation = Quaternion.identity;

            // Collect all particle systems in the effect prefab (root + all children, no duplicates)
            activeParticleSystems.Clear();
            ParticleSystem[] systems = activeParticleEffect.GetComponentsInChildren<ParticleSystem>(true);
            foreach (var ps in systems)
            {
                ps.Clear(true);
                ps.Play();
                activeParticleSystems.Add(ps);
            }
        }

        // Activation burst
        if (Data.activationEffectPrefab != null)
        {
            GameObject activationEffect = Object.Instantiate(Data.activationEffectPrefab, player.transform);
            activationEffect.transform.localPosition = Vector3.zero;
            activationEffect.transform.localRotation = Quaternion.identity;
            player.StartCoroutine(DestroyEffectDelayed(activationEffect, 1f));
        }

        // Audio
        if (Data.activationSound != null)
        {
            AudioSource.PlayClipAtPoint(Data.activationSound, player.transform.position);
        }
    }

    private void DisableEffects()
    {
        if (activeTrailEffect != null)
        {
            Object.Destroy(activeTrailEffect);
            activeTrailEffect = null;
        }

        // Stop (and then destroy) all child particle systems, not just the root
        foreach (var ps in activeParticleSystems)
        {
            if (ps != null)
                ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
        }
        activeParticleSystems.Clear();

        if (activeParticleEffect != null)
        {
            Object.Destroy(activeParticleEffect);
            activeParticleEffect = null;
        }
    }

    private IEnumerator DestroyEffectDelayed(GameObject effect, float delay)
    {
        yield return new WaitForSeconds(delay);
        if (effect != null)
        {
            Object.Destroy(effect);
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