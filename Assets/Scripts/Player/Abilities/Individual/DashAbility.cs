using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class DashAbility : BaseAbility
{
    [Header("Dash Settings")]
    private float dashSpeed = 20f;
    private float dashDistance = 5f;
    private LayerMask dashObstacles = -1;

    private CharacterController characterController;
    private Player_Movement movement;
    private Player_Health health;
    private Vector3 dashDirection;
    private bool isDashing;
    private float currentDashDistance;
    private SkillManager skillManager;
    private StyleSystem styleSystem;

    // Dynamic effect references
    private GameObject activeTrailEffect;
    private GameObject activeParticleEffect;
    private List<ParticleSystem> activeParticleSystems = new List<ParticleSystem>();

    public bool IsDashing => isDashing;

    public DashAbility(AbilityData data, Player player, SkillManager skillManager) : base(data, player)
    {
        this.skillManager = skillManager;
        this.styleSystem = player.styleSystem;

        characterController = player.GetComponent<CharacterController>();
        movement = player.movement;
        health = player.health;

        // Set default values - these can be overridden via AbilityData or inspector
        dashSpeed = 20f;
        dashDistance = 5f;
        dashObstacles = LayerMask.GetMask("Default", "Ground", "Wall");

        Debug.Log($"DashAbility created - Distance: {dashDistance}, Speed: {dashSpeed}, Cooldown: {data.cooldown}");

        if (movement == null) Debug.LogError("DashAbility: Could not find Player_Movement component!");
        if (health == null) Debug.LogError("DashAbility: Could not find Player_Health component!");
        if (characterController == null) Debug.LogError("DashAbility: Could not find CharacterController component!");
    }

    public override bool CanActivate()
    {
        return base.CanActivate() && MeetsActivationConditions();
    }

    protected override bool MeetsActivationConditions()
    {
        bool notDashing = !isDashing;
        bool healthOk = health != null && health.currentHealth > 0;
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
        // This method is called every frame while the ability is active
        if (!isDashing)
        {
            // Dash completed, finish the ability
            CompleteAbility();
        }
    }

    protected override void OnAbilityComplete()
    {
        Debug.Log("Dash completed!");
        isDashing = false;

        // Re-enable movement
        if (movement != null)
        {
            // Check if your Player_Movement has these methods
            // If not, remove or modify these calls
            try
            {
                var enableMethod = movement.GetType().GetMethod("SetMovementEnabled");
                if (enableMethod != null)
                    enableMethod.Invoke(movement, new object[] { true });
            }
            catch (System.Exception e)
            {
                Debug.LogWarning($"Could not re-enable movement: {e.Message}");
            }
        }

        // Disable invincibility
        if (health != null)
        {
            try
            {
                var invincibleMethod = health.GetType().GetMethod("SetInvincible");
                if (invincibleMethod != null)
                    invincibleMethod.Invoke(health, new object[] { false });
            }
            catch (System.Exception e)
            {
                Debug.LogWarning($"Could not disable invincibility: {e.Message}");
            }
        }

        // Clean up effects
        DisableEffects();

        // Trigger style system
        if (styleSystem != null)
        {
            styleSystem.OnAbilityUsed("Dash");
        }
    }

    private void CalculateDashDirection()
    {
        Vector3 inputDirection = Vector3.zero;

        // Try to get movement input - adapt this to your Player_Movement structure
        try
        {
            var moveInputField = movement.GetType().GetField("moveInput");
            if (moveInputField != null)
            {
                Vector2 moveInput = (Vector2)moveInputField.GetValue(movement);
                if (moveInput != Vector2.zero)
                {
                    inputDirection = new Vector3(moveInput.x, 0, moveInput.y).normalized;
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogWarning($"Could not get move input: {e.Message}");
        }

        // Fallback to input or forward direction
        if (inputDirection == Vector3.zero)
        {
            float horizontal = Input.GetAxis("Horizontal");
            float vertical = Input.GetAxis("Vertical");

            if (horizontal != 0 || vertical != 0)
            {
                inputDirection = new Vector3(horizontal, 0, vertical).normalized;
            }
            else
            {
                inputDirection = player.transform.forward;
            }
        }

        dashDirection = inputDirection;
    }

    private void CalculateActualDashDistance()
    {
        currentDashDistance = dashDistance;

        // Check for obstacles in dash path
        if (Physics.Raycast(player.transform.position, dashDirection, dashDistance, dashObstacles))
        {
            RaycastHit hit;
            if (Physics.Raycast(player.transform.position, dashDirection, out hit, dashDistance, dashObstacles))
            {
                currentDashDistance = Mathf.Max(hit.distance - 0.5f, 1f);
                Debug.Log($"Obstacle detected! Reduced dash distance to: {currentDashDistance}");
            }
        }
    }

    private void EnableEffects()
    {
        // Use the activationEffectPrefab from AbilityData for particle effects
        if (data.activationEffectPrefab != null)
        {
            activeParticleEffect = Object.Instantiate(data.activationEffectPrefab, player.transform);
            activeParticleEffect.transform.localPosition = Vector3.zero;
            activeParticleEffect.transform.localRotation = Quaternion.identity;

            // Collect all particle systems in the effect prefab
            activeParticleSystems.Clear();
            ParticleSystem[] systems = activeParticleEffect.GetComponentsInChildren<ParticleSystem>(true);
            foreach (var ps in systems)
            {
                ps.Clear(true);
                ps.Play();
                activeParticleSystems.Add(ps);
            }
        }

        // Audio
        if (data.activationSound != null)
        {
            AudioSource.PlayClipAtPoint(data.activationSound, player.transform.position);
        }

        Debug.Log("Dash effects enabled");
    }

    private void DisableEffects()
    {
        // Stop and destroy all particle systems
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

        if (activeTrailEffect != null)
        {
            Object.Destroy(activeTrailEffect);
            activeTrailEffect = null;
        }

        Debug.Log("Dash effects disabled");
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

        // Disable movement during dash
        if (movement != null)
        {
            try
            {
                var disableMethod = movement.GetType().GetMethod("SetMovementEnabled");
                if (disableMethod != null)
                    disableMethod.Invoke(movement, new object[] { false });
            }
            catch (System.Exception e)
            {
                Debug.LogWarning($"Could not disable movement: {e.Message}");
            }
        }

        // Enable invincibility during dash
        if (health != null)
        {
            try
            {
                var invincibleMethod = health.GetType().GetMethod("SetInvincible");
                if (invincibleMethod != null)
                    invincibleMethod.Invoke(health, new object[] { true });
            }
            catch (System.Exception e)
            {
                Debug.LogWarning($"Could not enable invincibility: {e.Message}");
            }
        }

        EnableEffects();

        // Perform the dash movement
        float dashTime = currentDashDistance / dashSpeed;
        float elapsedTime = 0f;
        Vector3 startPosition = player.transform.position;
        Vector3 targetPosition = startPosition + (dashDirection * currentDashDistance);

        Debug.Log($"Dashing from {startPosition} to {targetPosition} over {dashTime} seconds");

        while (elapsedTime < dashTime)
        {
            elapsedTime += Time.deltaTime;
            float progress = elapsedTime / dashTime;

            // Smooth dash movement
            Vector3 currentPosition = Vector3.Lerp(startPosition, targetPosition, progress);
            Vector3 frameMovement = currentPosition - player.transform.position;

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

        // Ensure we reach the exact target position
        if (characterController != null)
        {
            Vector3 finalMovement = targetPosition - player.transform.position;
            characterController.Move(finalMovement);
        }

        isDashing = false;
        Debug.Log("Dash movement completed");
    }

    // Public methods for external access
    public void SetDashParameters(float speed, float distance, LayerMask obstacles)
    {
        dashSpeed = speed;
        dashDistance = distance;
        dashObstacles = obstacles;
    }

    public float GetDashDistance() => dashDistance;
    public float GetDashSpeed() => dashSpeed;
    public LayerMask GetDashObstacles() => dashObstacles;
}