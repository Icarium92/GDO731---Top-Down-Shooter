using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HitBox : MonoBehaviour, IDamagable
{
    [SerializeField] protected float damageMultiplier = 1f;

    protected virtual void Awake()
    {

    }


    public virtual void TakeDamage(int damage)
    {
     
    }

    public Enemy_Melee EnemyHit()
    {
        Enemy_Melee enemy = GetComponentInParent<Enemy_Melee>();

        if(enemy != null)
        {
            return enemy;
        }

        return null;
    }
}
