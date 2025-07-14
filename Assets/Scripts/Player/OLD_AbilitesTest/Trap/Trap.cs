using System.Collections;
using System.Collections.Generic;
using Unity.Collections.LowLevel.Unsafe;
using UnityEngine;
using UnityEngine.Events;

public class Trap : MonoBehaviour
{
    //private Enemy enemy;
    public float trapInitialization;
    public float statusDuration;

    public LayerMask enemyLayerMask = 1 << 11;

    [SerializeField] private Enemy_Melee _trapEnemy;
    //public UnityEvent OnStyleLevel;

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.layer == LayerMask.NameToLayer("Enemy"))
        {
            HitBox enemyHitbox = other.GetComponent<HitBox>();

            if(enemyHitbox != null)
            {
                _trapEnemy = enemyHitbox.EnemyHit();
                StartCoroutine(TrapInitialization());
            }
        }
    }

    private IEnumerator WillThisWork()
    {
        _trapEnemy.runSpeed = 0;
        _trapEnemy.stateMachine.ChangeState(_trapEnemy.idleState);

        yield return new WaitForSeconds(statusDuration);

        if(_trapEnemy.stateMachine.currentState == _trapEnemy.deadState)
        {
            Debug.Log("enemyDead");
            StopAllCoroutines();
        }
        else
        {
            _trapEnemy.runSpeed = 3;
            _trapEnemy.stateMachine.ChangeState(_trapEnemy.chaseState);
        }

        Destroy(gameObject);
    }

    private IEnumerator TrapInitialization()
    {
        yield return new WaitForSeconds(trapInitialization);

        StartCoroutine(WillThisWork());
    }

}
