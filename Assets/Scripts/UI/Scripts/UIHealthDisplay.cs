using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIHealthDisplay : MonoBehaviour
{
    public Player_Health PlayerHealth;
    public Slider Slider;

    // Update is called once per frame
    void Update()
    {
        if (Slider != null)
        {
            Slider.value= PlayerHealth.currentHealth;
        }
    }
}
