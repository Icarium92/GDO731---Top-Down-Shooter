using UnityEngine;
using System.Collections;

public class SimpleChargeShot : MonoBehaviour
{
    [Header("Heavy Attack Settings")]
    public float maxChargeTime = 2f;
    public float minDamageMultiplier = 1f;
    public float maxDamageMultiplier = 3f;
    public int bulletsRequired = 3;

    [Header("Visual Effects")]
    public LineRenderer chargeBeam;
    public ParticleSystem chargeEffect;
    public AudioClip chargeSound;
    public AudioClip fireSound;

    public GameObject blueBulletPrefab;

    // Component references
    private Player_WeaponController weaponController;
    private AudioSource audioSource;

    // Charge state
    private bool isCharging = false;
    private float currentChargeTime = 0f;
    private bool canUseChargeShot = true;

    // Public properties for UI/other scripts
    public bool IsCharging => isCharging;
    public float ChargeProgress => currentChargeTime / maxChargeTime;
    public float CurrentDamageMultiplier => Mathf.Lerp(minDamageMultiplier, maxDamageMultiplier, ChargeProgress);

    void Start()
    {
        weaponController = GetComponent<Player_WeaponController>();
        audioSource = GetComponent<AudioSource>();

        if (chargeBeam != null)
            chargeBeam.enabled = false;
        if (chargeEffect != null)
            chargeEffect.gameObject.SetActive(false);
    }

    void Update()
    {
        if (!canUseChargeShot || !IsRifleEquipped())
            return;

        UpdateChargeEffects();

        // Auto-fire if max charge is reached
        if (isCharging && currentChargeTime >= maxChargeTime)
        {
            FireChargedShot();
        }
    }

    bool IsRifleEquipped()
    {
        return weaponController != null &&
               weaponController.CurrentWeapon() != null &&
               weaponController.CurrentWeapon().weaponType == WeaponType.Rifle;
    }

    bool CanStartCharge()
    {
        var weapon = weaponController.CurrentWeapon();
        return weapon != null &&
               weapon.bulletsInMagazine >= bulletsRequired &&
               weaponController.WeaponReady();
    }

    // Called by Player_WeaponController when HeavyAttack input is pressed
    public void StartCharging()
    {
        if (!canUseChargeShot || !IsRifleEquipped() || !CanStartCharge())
            return;

        isCharging = true;
        currentChargeTime = 0f;

        // Visual effects
        if (chargeBeam != null)
            chargeBeam.enabled = true;
        if (chargeEffect != null)
            chargeEffect.gameObject.SetActive(true);

        // Audio
        if (chargeSound != null && audioSource != null)
            audioSource.PlayOneShot(chargeSound);
    }

    void UpdateChargeBeam()
    {
        var gunPoint = weaponController.GunPoint();
        var direction = weaponController.BulletDirection();

        if (gunPoint != null && chargeBeam != null)
        {
            chargeBeam.SetPosition(0, gunPoint.position);
            chargeBeam.SetPosition(1, gunPoint.position + direction * 50f);
            // Beam width increases as charge increases
            float intensity = currentChargeTime / maxChargeTime;
            chargeBeam.startWidth = Mathf.Lerp(0.05f, 0.2f, intensity);
        }
    }

    void UpdateChargeEffects()
    {
        // Only charge if already started
        if (isCharging)
        {
            currentChargeTime += Time.deltaTime;
        }

        // Particle effect scales with charge progress
        if (chargeEffect != null && isCharging)
        {
            var main = chargeEffect.main;
            main.startLifetime = Mathf.Lerp(0.5f, 1.5f, currentChargeTime / maxChargeTime);
        }

        // Beam visualization update
        if (isCharging && chargeBeam != null)
        {
            UpdateChargeBeam();
        }
    }

    // Called by Player_WeaponController when HeavyAttack input is released or auto-fired
    public void FireChargedShot()
    {
        if (!isCharging) return;

        // Damage multiplier
        float chargePercent = currentChargeTime / maxChargeTime;
        float damageMultiplier = Mathf.Lerp(minDamageMultiplier, maxDamageMultiplier, chargePercent);

        // Consume bullets from rifle
        var weapon = weaponController.CurrentWeapon();
        weapon.bulletsInMagazine -= bulletsRequired;

        // Fire the charged bullet
        FireEnhancedBullet(damageMultiplier);

        // Play fire sound
        if (fireSound != null && audioSource != null)
            audioSource.PlayOneShot(fireSound);

        StopCharging();
        StartCoroutine(ChargeCooldown());
    }

    void FireEnhancedBullet(float damageMultiplier)
    {
        var weapon = weaponController.CurrentWeapon();
        int enhancedDamage = Mathf.RoundToInt(weapon.bulletDamage * damageMultiplier);

        // Use the blue bullet prefab if assigned
        var bulletPrefab = blueBulletPrefab != null ? blueBulletPrefab : weaponController.bulletPrefab;
        var gunPoint = weaponController.GunPoint();

        if (bulletPrefab != null && gunPoint != null)
        {
            GameObject newBullet = ObjectPool.instance.GetObject(bulletPrefab, gunPoint);
            newBullet.transform.rotation = Quaternion.LookRotation(gunPoint.forward);

            Bullet bulletScript = newBullet.GetComponent<Bullet>();
            bulletScript.BulletSetup(weaponController.whatIsAlly, enhancedDamage, weapon.gunDistance, weaponController.bulletImpactForce);

            Rigidbody rb = newBullet.GetComponent<Rigidbody>();
            Vector3 direction = weaponController.BulletDirection();
            rb.linearVelocity = direction * weaponController.bulletSpeed * 1.5f; // Enhanced speed
        }
    }

    void StopCharging()
    {
        isCharging = false;
        currentChargeTime = 0f;

        if (chargeBeam != null)
            chargeBeam.enabled = false;
        if (chargeEffect != null)
            chargeEffect.gameObject.SetActive(false);
    }

    IEnumerator ChargeCooldown()
    {
        canUseChargeShot = false;
        yield return new WaitForSeconds(1f); // 1 second cooldown after firing
        canUseChargeShot = true;
    }
}