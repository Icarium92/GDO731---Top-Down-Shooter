using UnityEngine;

public class DashTimer : AbilityBaseClass
{

    public override void Ability(Transform abilitySpawnPoint)
    {
        if (abilitySpawnPoint != null)
        {
            Debug.Log("dashTimer");
        }
    }
    
}
