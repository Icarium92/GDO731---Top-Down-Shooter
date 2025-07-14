using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AbilityBaseClass : AbilitiesSuperclass
{
    [Header("Ability")]
    public GameObject AbilityPrefab;

    public virtual void Ability(Transform abilitySpawnPoint)
    {

    }
}
