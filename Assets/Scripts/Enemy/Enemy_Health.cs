using UnityEngine;
using UnityEngine.Events;

public class Enemy_Health : HealthController
{
    public int CurrentHealth
    {
        get => currentHealth;
        set => currentHealth = value;
    }

    public UnityEvent onDeath = new UnityEvent();

    protected override void Awake()
    {
        base.Awake();
    }

    public override void ReduceHealth(int damage)
    {
        base.ReduceHealth(damage);
        if (ShouldDie())
        {
            onDeath.Invoke();
            gameObject.SetActive(false);
        }
    }

    // ADD THIS METHOD - Bridge method for ability system compatibility
    public void TakeDamage(int damage)
    {
        ReduceHealth(damage); // Delegates to your existing method
    }
}