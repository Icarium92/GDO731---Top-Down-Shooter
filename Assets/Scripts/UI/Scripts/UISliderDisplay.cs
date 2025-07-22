using UnityEngine;
using UnityEngine.UI;

public class UISliderDisplay : MonoBehaviour
{
    public FloatVariable Variable;
    [SerializeField] private Slider slider;

    // Update is called once per frame
    void Update()
    {
        if (slider != null && Variable != null)
        {
            slider.value = Variable.Value; 
        }
    }
}
