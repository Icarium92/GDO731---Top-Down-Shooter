using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DeadState_Range : EnemyState
{
    private Enemy_Range enemy;
    private bool interactionDisabled;

    public DeadState_Range(Enemy enemyBase, EnemyStateMachine stateMachine, string animBoolName) : base(enemyBase, stateMachine, animBoolName)
    {
        enemy = enemyBase as Enemy_Range;
    }

    public override void Enter()
    {
        base.Enter();

        if (enemy.throwGrenadeState.finishedThrowingGrenade == false)
            enemy.ThrowGrenade();

        interactionDisabled = false;

        enemy.anim.enabled = false;

        // Fixed: Safe check before stopping NavMeshAgent to avoid errors on inactive/invalid agents
        if (enemy.agent != null && enemy.agent.isActiveAndEnabled && enemy.agent.isOnNavMesh)
        {
            enemy.agent.isStopped = true;
        }
        else
        {
            Debug.LogWarning("NavMeshAgent not valid in DeadState_Range - skipping stop");
        }

        enemy.ragdoll.RagdollActive(true);

        stateTimer = 1.5f;
    }

    public override void Update()
    {
        base.Update();

        // Uncomment this if you want to disable interaction after death
        DisableInteractionIfShould();
    }

    private void DisableInteractionIfShould()
    {
        if (stateTimer < 0 && interactionDisabled == false)
        {
            interactionDisabled = true;
            enemy.ragdoll.RagdollActive(false);
            enemy.ragdoll.CollidersActive(false);
        }
    }
}
