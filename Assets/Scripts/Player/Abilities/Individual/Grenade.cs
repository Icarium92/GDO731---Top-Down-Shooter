using UnityEngine;
using System.Collections;

public class Grenade: MonoBehaviour
{
    [Header("Explosion Settings")]
    public float explosionDelay = 3f;
    public float explosionRadius = 5f;
    public int explosionDamage = 50;
    public float explosionForce = 1000f;
    public LayerMask damageableLayers = -1;//might need  to amend 
    [Header("Effects")]
    public GameObject explosionEffect;
    public AudioClip explosionSound;
    private float countdown;
    private bool hasExploded = false;
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

        foreach(Collider hit in hitColliders)
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
        if (explosionSound != null)
        {
            AudioSource.PlayClipAtPoint(explosionSound, transform.position);
        }
        // Destroy the grenade
        //Destroy(gameObject);//add objectpooling
        if (ObjectPool.instance != null)
        {
            ObjectPool.instance.ReturnObject(gameObject, 0f);
}
        else
        {
            // Fallback if no pool available
            gameObject.SetActive(false);
        }

    }
    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, explosionRadius);
    }
}
