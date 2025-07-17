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

    //public LayerMask enemyLayerMask = 1 << 11;

    //[SerializeField] private Enemy_Melee _trapEnemy;
    //public UnityEvent OnStyleIncrease;
    //public UnityEvent OnStyleDecrease;

    private void OnTriggerEnter(Collider other)
    {
        Enemy_Melee enemy = other.gameObject.GetComponentInParent<Enemy_Melee>();

        if(enemy != null)
        {
            StartCoroutine(TrapInitialization(enemy));
        }
    }

    private IEnumerator WillThisWork(Enemy_Melee enemy)
    {
        enemy.runSpeed = 0;
        enemy.stateMachine.ChangeState(enemy.idleState);

        yield return new WaitForSeconds(statusDuration);

        if (enemy.stateMachine.currentState == enemy.deadState)
        {
            StopAllCoroutines();
        }
        else
        {
            enemy.runSpeed = 3;
            enemy.stateMachine.ChangeState(enemy.chaseState);
        }

        Destroy(gameObject);
    }

    private IEnumerator TrapInitialization(Enemy_Melee enemy)
    {
        yield return new WaitForSeconds(trapInitialization);

        StartCoroutine(WillThisWork(enemy));
    }

}
