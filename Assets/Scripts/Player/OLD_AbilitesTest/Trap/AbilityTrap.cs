using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class AbilityTrap : AbilityBaseClass
{
  
    public override void Ability(Transform abilitySpawnPoint)
    {
        Instantiate(AbilityPrefab, abilitySpawnPoint.position, abilitySpawnPoint.rotation);
    }
}
