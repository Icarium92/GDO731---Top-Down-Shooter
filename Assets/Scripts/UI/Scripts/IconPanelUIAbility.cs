using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class IconPanelUIAbility : MonoBehaviour
{
    public AbilitiesSuperclass Ability;
    //public BaseDefaultWeapon Weapon;

    public TextMeshProUGUI CooldownTextComponent;
    public Image AbilityIcon;
    public Image AbilityPanel;

    private void Start()
    {
        
    }

    private void Update()
    {
        DisplayIcon();
    }

    public void DisplayIcon()
    {
        if(Ability != null)
        {
            if (Ability.Cooldown == Ability.CooldownTimer)
            {
                CooldownTextComponent.text = string.Empty;
                AbilityIcon.enabled = true;
                AbilityPanel.enabled = false;
            }
            else
            {
                AbilityIcon.enabled = false; 
                AbilityPanel.enabled = true;
                CooldownTextComponent.text = Ability.CooldownTimer.ToString("F0");
            }
        }
    }

}
