using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class OldIconPanelUIAbility : MonoBehaviour
{
    public AbilitiesSuperclass Ability;
    //public BaseDefaultWeapon Weapon;

    public TextMeshProUGUI CooldownTextComponent;
    public Image AbilityIcon;
    public Image AbilityPanel;

    [Header("Audio")]
    [SerializeField] private AudioSource pointerEnterSFX;
    [SerializeField] private AudioSource pointerDownSFX;

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
                AbilityPanel.fillAmount = 1;
            }
            else
            {
                AbilityIcon.enabled = false;
                AbilityPanel.enabled = true;
                AbilityPanel.fillAmount -= 1 / Ability.CooldownTimer * Time.deltaTime;
                CooldownTextComponent.text = Ability.CooldownTimer.ToString("F0");
            }
        }
    }

    public void AssignAudioSource()
    {
        pointerEnterSFX = GameObject.Find("UI_PointerEnter").GetComponent<AudioSource>();
        pointerDownSFX = GameObject.Find("UI_PointerDown").GetComponent<AudioSource>();
    }
}
