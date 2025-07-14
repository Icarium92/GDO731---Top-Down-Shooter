using UnityEngine;
using UnityEngine.Events;

// Enemy_Health.cs - Derived from HealthController with event and overrides for wave integration
public class Enemy_Health : HealthController
{
    // Public property mirroring base currentHealth - why? Provides access for resetting/scaling without direct field manipulation
    public int CurrentHealth
    {
        get => currentHealth;
        set => currentHealth = value;
    }

    // Event for death notification - why? Allows WaveManager to track defeats event-driven, avoiding polling
    public UnityEvent onDeath = new UnityEvent();

    // Override to extend base Awake - why? Ensures base initialization runs, fixing the hiding warning
    protected override void Awake()
    {
        base.Awake(); // Calls base to set currentHealth = maxHealth
        // Add any enemy-specific init here if needed
    }

    // Override base ReduceHealth for custom logic - why? Integrates death event and pooling deactivation
    public override void ReduceHealth(int damage)
    {
        base.ReduceHealth(damage); // Apply damage via base
        if (ShouldDie()) // Use base method for death check
        {
            onDeath.Invoke(); // Notify listeners (e.g., WaveManager)
            gameObject.SetActive(false); // Deactivate for pooling - add effects or cleanup here
        }
    }

    // If you need float damage later, we can add an overload or convert base to float
}
