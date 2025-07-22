using UnityEngine;

public class Trap : MonoBehaviour
{
    [Header("Trap Settings")]
    public int damage = 75;
    public LayerMask targetLayers = -1;
    public float triggerRadius = 2f;
    public float armingDelay = 1f;

    private bool isArmed = false;
    private bool hasTriggered = false;
    private SphereCollider triggerCollider;

    public void SetupTrap(int trapDamage, LayerMask layers)
    {
        damage = trapDamage;
        targetLayers = layers;

        // Initialize the trap
        triggerCollider = gameObject.AddComponent<SphereCollider>();
        triggerCollider.isTrigger = true;
        triggerCollider.radius = triggerRadius;

        Invoke(nameof(ArmTrap), armingDelay);
    }

    private void ArmTrap()
    {
        isArmed = true;
    }

    private void OnTriggerEnter(Collider other)
    {
        if (!isArmed || hasTriggered)
            return;

        if (((1 << other.gameObject.layer) & targetLayers) == 0)
            return;

        TriggerTrap(other.gameObject);
    }

    private void TriggerTrap(GameObject target)
    {
        hasTriggered = true;

        var health = target.GetComponent<Enemy_Health>();
        if (health != null)
        {
            health.TakeDamage(damage);
        }

        var rb = target.GetComponent<Rigidbody>();
        if (rb != null)
        {
            Vector3 direction = (target.transform.position - transform.position).normalized;
            rb.AddForce(direction * 300f, ForceMode.Impulse);
        }

        Destroy(gameObject, 0.5f);
    }
}