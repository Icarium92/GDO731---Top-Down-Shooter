using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;

public class AbilityAOESpell : AbilityBaseClass
{

    [Header("Events")]
    public UnityEvent onStyleIncrease;
    public UnityEvent onStyleLevel;
    public UnityEvent onStyleBoost;
    public UnityEvent onStyleDecrease;

    [Header("AOESpell")]
    public int AOESpellDamage;
    [SerializeField] private ParticleSystem damageParticles;
    [SerializeField] private int layer = 8;
    private ParticleSystem insatanceDamageParticles;
    private int layerAsLayerMask;

    public float castRadius;

    private void Start()
    {
        layerAsLayerMask = (1 << layer);
    }

    public void CheckAOE(Transform abiltySpawnPoint)
    {
        Collider[] colliders = Physics.OverlapSphere(abiltySpawnPoint.position, castRadius, layerAsLayerMask);
        int hits = 0;

        foreach (Collider c in colliders)
        {
            if (c.TryGetComponent<Enemy>(out Enemy enemy))
            {
                if (enemy != null)
                {
                    Debug.Log("enemyhit");
                }
            }
        }

        switch (hits)
        {
            case 0:
                onStyleDecrease?.Invoke();
                break;
            case 1:
                onStyleIncrease?.Invoke();
                break;
            case 2:
                onStyleLevel?.Invoke();
                break;
            case > 2:
                onStyleBoost?.Invoke();
                break;
        }
    }

    private IEnumerator AttackSequence(Transform abiltySpawnPoint)
    {
        yield return new WaitForSeconds(0.25f);
        //start particles
        SpawnDamageParticles(abiltySpawnPoint);
        CheckAOE(abiltySpawnPoint);
        yield return new WaitForSeconds(1f);
        //end particles

    }
    private void SpawnDamageParticles(Transform abiltySpawnPoint)
    {
        if (damageParticles != null)
        {
            insatanceDamageParticles = Instantiate(damageParticles, abiltySpawnPoint);
        }
    }

    public override void Ability(Transform abilitySpawnPoint)
    {
        StartCoroutine(AttackSequence(abilitySpawnPoint));
    }
}
