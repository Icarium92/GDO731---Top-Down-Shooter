using UnityEngine;
using System.Collections;

public class Grenade : MonoBehaviour
{
    [Header("Explosion Settings")]
    public float explosionDelay = 3f;
    public float explosionRadius = 5f;
    public int explosionDamage = 50;
    public float explosionForce = 1000f;
    public LayerMask damageableLayers = -1; // might need to amend 

    [Header("Effects")]
    public GameObject explosionEffect;
    public AudioClip explosionSound;

    private float countdown;
    private bool hasExploded = false;

    // Audio Source for grenade SFX (assigned from outside)
    private AudioSource grenadeSFX;

    private void Start()
    {
        countdown = explosionDelay;
    }

    private void Update()
    {
        countdown -= Time.deltaTime;
        if (countdown <= 0f && !hasExploded)
        {
            Explode();
        }
    }

    private void Explode()
    {
        hasExploded = true;

        // Find all objects in explosion radius
        Collider[] hitColliders = Physics.OverlapSphere(transform.position, explosionRadius, damageableLayers);

        foreach (Collider hit in hitColliders)
        {
            // Apply damage to damageable objects
            IDamagable damageable = hit.GetComponent<IDamagable>();
            if (damageable != null)
            {
                float distance = Vector3.Distance(transform.position, hit.transform.position);
                float damageMultiplier = 1f - (distance / explosionRadius);
                int finalDamage = Mathf.RoundToInt(explosionDamage * damageMultiplier);
                damageable.TakeDamage(finalDamage);
            }

            // Apply explosion force to rigidbodies
            Rigidbody rb = hit.GetComponent<Rigidbody>();
            if (rb != null)
            {
                rb.AddExplosionForce(explosionForce, transform.position, explosionRadius);
            }
        }

        // Spawn explosion effects
        if (explosionEffect != null)
        {
            Instantiate(explosionEffect, transform.position, Quaternion.identity);
        }

        // Play explosion sound at grenade position (optional)
        if (explosionSound != null)
        {
            AudioSource.PlayClipAtPoint(explosionSound, transform.position);
        }

        // Return grenade to pool or deactivate if no pool available
        if (ObjectPool.instance != null)
        {
            ObjectPool.instance.ReturnObject(gameObject, 0f);
        }
        else
        {
            gameObject.SetActive(false);
        }
    }

    // Public method to initialize grenade with audio source and start delayed SFX coroutine
    public void Initialize(AudioSource grenadeSFX)
    {
        this.grenadeSFX = grenadeSFX;
        StartCoroutine(PlayGrenadeSFXDelayed(0.5f));
    }

    // Coroutine to play grenade SFX after delay
    private IEnumerator PlayGrenadeSFXDelayed(float delay)
    {
        yield return new WaitForSeconds(delay);
        if (grenadeSFX != null && !grenadeSFX.isPlaying)
        {
            grenadeSFX.Play();
        }
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, explosionRadius);
    }
}