using TMPro;
using UnityEngine;

public class UIAmmoDisplay : MonoBehaviour
{
    [SerializeField] private Player_WeaponController WeaponController;
    [SerializeField] private TextMeshProUGUI AmmoTextComponent;

    private void Update()
    {
        if(WeaponController != null && AmmoTextComponent != null)
        {
            AmmoTextComponent.text = WeaponController.currentWeapon.bulletsInMagazine.ToString() + " / " + WeaponController.currentWeapon.magazineCapacity.ToString();

            if(WeaponController.currentWeapon.bulletsInMagazine < 1)
            {
                AmmoTextComponent.text = "Reload";
            }
        }
    }
}
