using UnityEngine;
using UnityEngine.UI;

public class ChargeBarUI : MonoBehaviour
{
    public Slider chargeBarSlider;          // Drag your ChargeBarSlider here
    private Player_ChargeShot chargeShot;

    void Start()
    {
        // Automatic search if not assigned (or assign in Inspector)
        if (chargeBarSlider == null)
        {
            chargeBarSlider = GetComponentInChildren<Slider>();
        }

        chargeShot = FindFirstObjectByType<Player_ChargeShot>();
        chargeBarSlider.gameObject.SetActive(false);
        chargeBarSlider.value = 0f;
    }

    void Update()
    {
        if (chargeShot == null) return;

        if (chargeShot.IsCharging)
        {
            chargeBarSlider.gameObject.SetActive(true);
            chargeBarSlider.value = Mathf.Clamp01(chargeShot.ChargeProgress);
        }
        else
        {
            // Hide or reset when not charging
            chargeBarSlider.value = 0f;
            chargeBarSlider.gameObject.SetActive(false);
        }
    }
}