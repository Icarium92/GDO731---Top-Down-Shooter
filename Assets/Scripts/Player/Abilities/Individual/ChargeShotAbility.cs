using UnityEngine;

public class ChargeShotAbility : BaseAbility
{
    private Player_ChargeShot chargeShotComponent;
    private Player_WeaponController weaponController;
    private StyleSystem styleSystem;
    private bool isActivated = false;

    public bool IsCharging => chargeShotComponent != null && chargeShotComponent.IsCharging;
    public float ChargeProgress => chargeShotComponent?.ChargeProgress ?? 0f;

    public ChargeShotAbility(AbilityData data, Player player) : base(data, player)
    {
        chargeShotComponent = player.GetComponent<Player_ChargeShot>();
        weaponController = player.GetComponent<Player_WeaponController>();
        styleSystem = player.styleSystem;

        if (chargeShotComponent == null)
        {
            Debug.LogError("ChargeShotAbility: SimpleChargeShot component not found on Player!");
        }

        if (weaponController == null)
        {
            Debug.LogError("ChargeShotAbility: Player_WeaponController component not found on Player!");
        }
    }

    protected override bool MeetsActivationConditions()
    {
        return chargeShotComponent != null &&
               weaponController != null &&
               !IsPlayerDead() &&
               !IsCharging &&
               IsRifleEquipped() &&
               CanStartCharge();
    }

    private bool IsPlayerDead()
    {
        return player.health != null && player.health.currentHealth <= 0;
    }

    private bool IsRifleEquipped()
    {
        return weaponController != null &&
               weaponController.CurrentWeapon() != null &&
               weaponController.CurrentWeapon().weaponType == WeaponType.Rifle;
    }

    private bool CanStartCharge()
    {
        if (weaponController == null) return false;

        var weapon = weaponController.CurrentWeapon();
        return weapon != null &&
               weapon.bulletsInMagazine >= 3 &&
               weaponController.WeaponReady();
    }

    protected override void OnAbilityExecute()
    {
        if (chargeShotComponent != null)
        {
            chargeShotComponent.StartCharging();
            isActivated = true;
        }
    }

    protected override void UpdateAbilityLogic()
    {
        if (isActivated && chargeShotComponent != null && !chargeShotComponent.IsCharging)
        {
            CompleteAbility();
        }
    }

    protected override void OnAbilityComplete()
    {
        if (isActivated)
        {
            if (chargeShotComponent != null && chargeShotComponent.IsCharging)
            {
                chargeShotComponent.FireChargedShot();
            }

            if (styleSystem != null)
            {
                styleSystem.OnAbilityUsed("ChargeShot");
            }

            isActivated = false;
            StartCooldown();
        }
    }

    public void FireCharge()
    {
        if (chargeShotComponent != null && chargeShotComponent.IsCharging)
        {
            CompleteAbility();
        }
    }

    public void CancelCharge()
    {
        if (isActivated && chargeShotComponent != null && chargeShotComponent.IsCharging)
        {
            CompleteAbility();
        }
    }

    public override bool CanActivate()
    {
        return base.CanActivate() && !isActivated;
    }
}