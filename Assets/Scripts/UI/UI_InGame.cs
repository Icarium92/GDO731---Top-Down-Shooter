using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;


public class UI_InGame : MonoBehaviour
{
    [Header("Health")]
    [SerializeField] private Image healthBar;

    [Header("Weapons")]
    [SerializeField] private UI_WeaponSlot[] weaponSlots_UI;

    private void Awake()
    {
        weaponSlots_UI = GetComponentsInChildren<UI_WeaponSlot>();
    }

    public void UpdateWeaponUI(List<Weapon> weaponsSlots, Weapon currentWeapon)
    {
        for (int i = 0; i < weaponSlots_UI.Length; i++)
        {
            if (i < weaponsSlots.Count)
            {
                bool isActiveWeapon = weaponsSlots[i] == currentWeapon;
                weaponSlots_UI[i].UpdateWeaponSlot(weaponsSlots[i], isActiveWeapon);
            }
            else
            {
                weaponSlots_UI[i].UpdateWeaponSlot(null, false);
            }
        }

    }

    public void UpdateHealthUI(float currentHealth, float maxHealth)
    {
        healthBar.fillAmount = currentHealth / maxHealth;
    }
}

