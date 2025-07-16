using UnityEngine;

public class Bullet : MonoBehaviour
{
    private int bulletDamage;
    private float impactForce;
    private BoxCollider cd;
    private Rigidbody rb;
    private MeshRenderer meshRenderer;
    private TrailRenderer trailRenderer;

    [SerializeField] private GameObject bulletImpactFX;    // Default impact effect

    private Vector3 startPosition;
    private float flyDistance;
    private bool bulletDisabled;
    private LayerMask allyLayerMask;
    private bool useSniperImpact; // Was this fired as a charge/blue shot?

    protected virtual void Awake()
    {
        cd = GetComponent<BoxCollider>();
        rb = GetComponent<Rigidbody>();
        meshRenderer = GetComponent<MeshRenderer>();
        trailRenderer = GetComponent<TrailRenderer>();
    }

    /// <summary>
    /// Setup for each bullet spawn.
    /// </summary>
    public void BulletSetup(
        LayerMask allyLayerMask,
        int bulletDamage,
        float flyDistance = 100,
        float impactForce = 100,
        bool useSniperImpact = false    // Pass true for charged/blue shots
    )
    {
        this.allyLayerMask = allyLayerMask;
        this.impactForce = impactForce;
        this.bulletDamage = bulletDamage;
        this.useSniperImpact = useSniperImpact;
        bulletDisabled = false;

        cd.enabled = true;
        meshRenderer.enabled = true;
        trailRenderer.Clear();
        trailRenderer.time = 0.25f;

        startPosition = transform.position;
        this.flyDistance = flyDistance + 0.5f;
    }

    protected virtual void Update()
    {
        FadeTrailIfNeeded();
        DisableBulletIfNeeded();
        ReturnToPoolIfNeeded();
    }

    protected void ReturnToPoolIfNeeded()
    {
        if (trailRenderer.time <= 0)
            ReturnBulletToPool();
    }

    protected void DisableBulletIfNeeded()
    {
        if (Vector3.Distance(startPosition, transform.position) > flyDistance && !bulletDisabled)
        {
            cd.enabled = false;
            meshRenderer.enabled = false;
            bulletDisabled = true;
            ReturnBulletToPool();
        }
    }

    protected void FadeTrailIfNeeded()
    {
        if (Vector3.Distance(startPosition, transform.position) > flyDistance - 1.5f)
        {
            trailRenderer.time -= 2 * Time.deltaTime;
        }
    }

    protected virtual void OnCollisionEnter(Collision collision)
    {
        if (!FriendlyFire)
        {
            if ((allyLayerMask.value & (1 << collision.gameObject.layer)) != 0)
            {
                ReturnBulletToPool(0.1f);
                return;
            }
        }

        CreateImpactFx();
        ReturnBulletToPool();

        IDamagable damagable = collision.gameObject.GetComponent<IDamagable>();
        damagable?.TakeDamage(bulletDamage);

        ApplyBulletImpactToEnemy(collision);
    }

    private void ApplyBulletImpactToEnemy(Collision collision)
    {
        Enemy enemy = collision.gameObject.GetComponentInParent<Enemy>();
        if (enemy != null)
        {
            Vector3 force = rb.linearVelocity.normalized * impactForce;
            Rigidbody hitRigidbody = collision.collider.attachedRigidbody;
            enemy.BulletImpact(force, collision.contacts[0].point, hitRigidbody);
        }
    }

    protected void ReturnBulletToPool(float delay = 0)
    {
        ObjectPool.instance.ReturnObject(gameObject, delay);
    }

    protected virtual void CreateImpactFx()
    {
        GameObject newImpactFx = ObjectPool.instance.GetObject(bulletImpactFX, transform);
        ObjectPool.instance.ReturnObject(newImpactFx, 1);
    }

    private bool FriendlyFire => GameManager.Instance.friendlyFire;
}