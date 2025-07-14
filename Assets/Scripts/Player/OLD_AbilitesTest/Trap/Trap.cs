using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Trap : MonoBehaviour
{
    //private Enemy enemy;
    public float trapInitialization;
    public float statusDuration;

    public UnityEvent OnStyleLevel;

    private void OnTriggerEnter(Collider other)
    {
        //enemy = other.GetComponent<Enemy>();

        //if(enemy != null)
        //{
        //    OnStyleLevel?.Invoke();
        //    StartCoroutine(TrapInitialization());
        //}
    }

    private IEnumerator WillThisWork()
    {
        //enemy.HasStatusEffect = true;

        yield return new WaitForSeconds(statusDuration);

        //if(enemy != null)
        //{
        //    enemy.HasStatusEffect = false;
        //}

        //Destroy(gameObject);

    }

    private IEnumerator TrapInitialization()
    {
        yield return new WaitForSeconds(trapInitialization);

        StartCoroutine(WillThisWork());
    }

}
