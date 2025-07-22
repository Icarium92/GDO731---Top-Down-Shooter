using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class IconPanelUIAbility : MonoBehaviour
{
    [Header("UI References")]
    public TextMeshProUGUI CooldownTextComponent;
    public Image AbilityIcon;
    public Image AbilityPanel;

    [Header("Ability Configuration")]
    public AbilityType abilityType;
    public Sprite abilityIconSprite;

    [Header("Visual Settings")]
    public Color readyColor = Color.white;
    public Color cooldownColor = Color.gray;

    // Internal references
    private SkillManager skillManager;
    private IAbility currentAbility;
    private bool isInitialized = false;

    private void Start()
    {
        InitializePanel();
    }

    private void Update()
    {
        if (isInitialized)
        {
            DisplayIcon();
        }
    }

    private void InitializePanel()
    {
        // Find the SkillManager (usually on the Player)
        skillManager = FindFirstObjectByType<SkillManager>();

        if (skillManager == null)
        {
            Debug.LogError($"IconPanelUIAbility: No SkillManager found in scene!");
            return;
        }

        // Get the specific ability this panel represents
        currentAbility = skillManager.GetAbility(abilityType);

        if (currentAbility == null)
        {
            Debug.LogWarning($"IconPanelUIAbility: No {abilityType} ability found in SkillManager!");
            return;
        }

        // Set up the icon
        if (abilityIconSprite != null && AbilityIcon != null)
        {
            AbilityIcon.sprite = abilityIconSprite;
        }

        isInitialized = true;
        Debug.Log($"IconPanelUIAbility initialized for {abilityType}");
    }

    public void DisplayIcon()
    {
        if (currentAbility == null) return;

        // Check if ability is on cooldown
        if (currentAbility.IsOnCooldown)
        {
            ShowCooldownState();
        }
        else
        {
            ShowReadyState();
        }

        // Update charges display for abilities that have them
        UpdateChargesDisplay();
    }

    private void ShowCooldownState()
    {
        // Show cooldown overlay
        if (AbilityPanel != null)
        {
            AbilityPanel.enabled = true;
            AbilityPanel.fillAmount = 1f - currentAbility.GetCooldownProgress();
            AbilityPanel.color = cooldownColor;
        }

        // Show cooldown text
        if (CooldownTextComponent != null)
        {
            float remainingTime = currentAbility.CooldownProgress * GetAbilityCooldownDuration();
            CooldownTextComponent.text = Mathf.Ceil(remainingTime).ToString("F0");
        }

        // Dim the icon
        if (AbilityIcon != null)
        {
            AbilityIcon.color = cooldownColor;
        }
    }

    private void ShowReadyState()
    {
        // Hide cooldown overlay
        if (AbilityPanel != null)
        {
            AbilityPanel.enabled = false;
            AbilityPanel.fillAmount = 0f;
        }

        // Clear cooldown text
        if (CooldownTextComponent != null)
        {
            CooldownTextComponent.text = string.Empty;
        }

        // Restore icon color
        if (AbilityIcon != null)
        {
            AbilityIcon.color = readyColor;
        }
    }

    private void UpdateChargesDisplay()
    {
        // Handle charge-based abilities (Grenade and Trap)
        string chargeText = "";

        switch (abilityType)
        {
            case AbilityType.Grenade:
                if (currentAbility is GrenadeAbility grenadeAbility)
                {
                    int charges = grenadeAbility.GrenadesRemaining;
                    if (charges < 3) // Only show if not at max
                    {
                        chargeText = charges.ToString();
                    }
                }
                break;

            case AbilityType.Trap:
                if (currentAbility is TrapAbility trapAbility)
                {
                    int charges = trapAbility.TrapsRemaining;
                    if (charges < 2) // Only show if not at max
                    {
                        chargeText = charges.ToString();
                    }
                }
                break;
        }

        // Display charge count if applicable
        if (!string.IsNullOrEmpty(chargeText) && !currentAbility.IsOnCooldown)
        {
            if (CooldownTextComponent != null)
            {
                CooldownTextComponent.text = chargeText;
            }
        }
    }

    private float GetAbilityCooldownDuration()
    {
        if (currentAbility?.Data != null)
        {
            return currentAbility.Data.cooldown;
        }
        return 1f; // Fallback value
    }

    // Public method to manually refresh the panel
    public void RefreshPanel()
    {
        if (skillManager != null)
        {
            currentAbility = skillManager.GetAbility(abilityType);
        }
    }

    // Handle clicks on the ability icon (optional)
    public void OnAbilityIconClicked()
    {
        if (skillManager != null && currentAbility != null && currentAbility.CanActivate())
        {
            skillManager.TryActivateAbility(abilityType);
        }
    }
}
