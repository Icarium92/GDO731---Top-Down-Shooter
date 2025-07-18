using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class Player_WeaponController : MonoBehaviour
{
    [SerializeField] public LayerMask whatIsAlly;
    [Space]
    private Player player;
    private const float REFERENCE_BULLET_SPEED = 20;

    [Header("Weapon Data")]
    [SerializeField] private Weapon_Data defaultWeaponData;
    [SerializeField] private Weapon currentWeapon;

    private bool weaponReady = true;
    private bool isShooting;

    [Header("Bullet Details")]
    [SerializeField] public float bulletImpactForce = 100;
    [SerializeField] public GameObject bulletPrefab;
    [SerializeField] public float bulletSpeed = 20;
    [SerializeField] private Transform weaponHolder;

    [Header("Inventory")]
    [SerializeField] private int maxSlots = 2;
    [SerializeField] private List<Weapon> weaponSlots = new List<Weapon>();
    [SerializeField] private GameObject weaponPickupPrefab;

    private void Start()
    {
        player = GetComponent<Player>();
        AssignInputEvents();

        Invoke(nameof(EquipStartingWeapon), 0.1f);
    }

    private void Update()
    {
        if (isShooting)
            Shoot();
    }

    #region Weapon Slots Management

    private void EquipStartingWeapon()
    {
        weaponSlots[0] = new Weapon(defaultWeaponData);
        EquipWeapon(0);
    }

    private void EquipWeapon(int i)
    {
        if (i >= weaponSlots.Count)
            return;

        SetWeaponReady(false);

        currentWeapon = weaponSlots[i];
        player.weaponVisuals.PlayWeaponEquipAnimation();

        CameraManager.instance.ChangeCameraDistance(currentWeapon.cameraDistance);

        UpdateWeaponUI();
    }

    public void PickupWeapon(Weapon newWeapon)
    {
        if (WeaponInSlots(newWeapon.weaponType) != null)
        {
            WeaponInSlots(newWeapon.weaponType).totalReserveAmmo += newWeapon.bulletsInMagazine;
            return;
        }

        if (weaponSlots.Count >= maxSlots && newWeapon.weaponType != currentWeapon.weaponType)
        {
            int weaponIndex = weaponSlots.IndexOf(currentWeapon);
            player.weaponVisuals.SwitchOffWeaponModels();
            weaponSlots[weaponIndex] = newWeapon;
            CreateWeaponOnTheGround();
            EquipWeapon(weaponIndex);
            return;
        }

        weaponSlots.Add(newWeapon);
        player.weaponVisuals.SwitchOnBackupWeaponModel();

        UpdateWeaponUI();
    }

    private void DropWeapon()
    {
        if (HasOnlyOneWeapon())
            return;

        CreateWeaponOnTheGround();
        weaponSlots.Remove(currentWeapon);
        EquipWeapon(0);
    }

    private void CreateWeaponOnTheGround()
    {
        GameObject droppedWeapon = ObjectPool.instance.GetObject(weaponPickupPrefab, transform);
        droppedWeapon.GetComponent<Pickup_Weapon>()?.SetupPickupWeapon(currentWeapon, transform);
    }

    public void SetWeaponReady(bool ready)
    {
        weaponReady = ready;
    }

    #endregion

    public void UpdateWeaponUI()
    {
        UI.instance.inGameUI.UpdateWeaponUI(weaponSlots, currentWeapon);
    }

    private IEnumerator BurstFire()
    {
        SetWeaponReady(false);

        for (int i = 1; i <= currentWeapon.bulletsPerShot; i++)
        {
            FireSingleBullet();
            yield return new WaitForSeconds(currentWeapon.burstFireDelay);

            if (i >= currentWeapon.bulletsPerShot)
                SetWeaponReady(true);
        }
    }

    private void Shoot()
    {
        if (WeaponReady() == false) return;
        if (currentWeapon.CanShoot() == false) return;

        player.weaponVisuals.PlayFireAnimation();

        if (currentWeapon.shootType == ShootType.Single)
            isShooting = false;

        if (currentWeapon.BurstActivated() == true)
        {
            StartCoroutine(BurstFire());
            return;
        }

        FireSingleBullet();
        TriggerEnemyDodge();
    }

    private void FireSingleBullet()
    {
        currentWeapon.bulletsInMagazine--;
        UpdateWeaponUI();

        GameObject newBullet = ObjectPool.instance.GetObject(bulletPrefab, GunPoint());
        newBullet.transform.rotation = Quaternion.LookRotation(GunPoint().forward);

        Rigidbody rbNewBullet = newBullet.GetComponent<Rigidbody>();
        Bullet bulletScript = newBullet.GetComponent<Bullet>();

        bulletScript.BulletSetup(whatIsAlly, currentWeapon.bulletDamage, currentWeapon.gunDistance, bulletImpactForce);

        Vector3 bulletsDirection = currentWeapon.ApplySpread(BulletDirection());
        rbNewBullet.mass = REFERENCE_BULLET_SPEED / bulletSpeed;
        rbNewBullet.linearVelocity = bulletsDirection * bulletSpeed;
    }

    private void Reload()
    {
        SetWeaponReady(false);
        player.weaponVisuals.PlayReloadAnimation();

        // We do the refill of the bullets in Player_AnimationEvents
        // We UpdateWeaponUI in Player_AnimationEvents as well
    }

    public Vector3 BulletDirection()
    {
        Transform aim = player.aim.Aim();
        Vector3 direction = (aim.position - GunPoint().position).normalized;

        if (player.aim.CanAimPrecisly() == false || player.aim.Target() == null)
        {
            direction.y = 0;
        }

        return direction;
    }

    public bool HasOnlyOneWeapon() => weaponSlots.Count <= 1;

    public Weapon WeaponInSlots(WeaponType weaponType)
    {
        foreach (Weapon weapon in weaponSlots)
        {
            if (weapon.weaponType == weaponType)
                return weapon;
        }
        return null;
    }

    public Weapon CurrentWeapon() => currentWeapon;

    public Transform GunPoint() => player.weaponVisuals.CurrentWeaponModel().gunPoint;

    public bool WeaponReady() => weaponReady;

    private void TriggerEnemyDodge()
    {
        Vector3 rayOrigin = GunPoint().position;
        Vector3 rayDirection = BulletDirection();

        if (Physics.Raycast(rayOrigin, rayDirection, out RaycastHit hit, Mathf.Infinity))
        {
            Enemy_Melee enemyMelee = hit.collider.gameObject.GetComponentInParent<Enemy_Melee>();
            if (enemyMelee != null)
            {
                enemyMelee.ActivateDodgeRoll();
            }
        }
    }

    #region Input Events

    private void AssignInputEvents()
    {
        PlayerControls controls = player.controls;

        controls.Character.Fire.performed += context => isShooting = true;
        controls.Character.Fire.canceled += context => isShooting = false;

        // Heavy Attack input events - NEW
        controls.Character.HeavyAttack.performed += context => OnHeavyAttackStarted();
        controls.Character.HeavyAttack.canceled += context => OnHeavyAttackReleased();

        controls.Character.EquipSlot1.performed += context => EquipWeapon(0);
        controls.Character.EquipSlot2.performed += context => EquipWeapon(1);
        controls.Character.EquipSlot3.performed += context => EquipWeapon(2);
        controls.Character.EquipSlot4.performed += context => EquipWeapon(3);
        controls.Character.EquipSlot5.performed += context => EquipWeapon(4);

        controls.Character.DropCurrentWeapon.performed += context => DropWeapon();

        controls.Character.Reload.performed += context =>
        {
            if (currentWeapon.CanReload() && WeaponReady())
                Reload();
        };

        controls.Character.ToogleWeaponMode.performed += context => currentWeapon.ToggleBurst();
    }

    private void OnHeavyAttackStarted()
    {
        Debug.Log("Heavy Attack Started!"); // ADD THIS
        var chargeShot = GetComponent<SimpleChargeShot>();
        if (chargeShot != null)
            chargeShot.StartCharging();
    }

    private void OnHeavyAttackReleased()
    {
        Debug.Log("Heavy Attack Released!"); // ADD THIS
        var chargeShot = GetComponent<SimpleChargeShot>();
        if (chargeShot != null)
            chargeShot.FireChargedShot();
    }

    #endregion
}