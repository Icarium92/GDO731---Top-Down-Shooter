using UnityEngine;
using UnityEngine.AI;
using System.Collections;
using UnityEngine.UI;

[RequireComponent(typeof(NavMeshAgent))]
public class Enemy : MonoBehaviour
{
    [Header("Health bar")]
    public Slider healthBar;
    [Space]

    public LayerMask whatIsAlly;
    public LayerMask whatIsPlayer;
    [Space]
    public int healthPoints = 20;

    [Header("Idle data")]
    public float idleTime;
    public float aggresionRange;

    [Header("Move data")]
    public float walkSpeed = 1.5f;
    public float runSpeed = 3;
    public float turnSpeed;
    private bool manualMovement;
    private bool manualRotation;

    [SerializeField] private Transform[] patrolPoints;
    private Vector3[] patrolPointsPosition;
    private int currentPatrolIndex;

    public bool inBattleMode { get; private set; }
    protected bool isMeleeAttackReady;

    public Transform player { get; private set; }
    public Animator anim { get; private set; }
    public NavMeshAgent agent { get; private set; }
    public EnemyStateMachine stateMachine { get; private set; }
    public Enemy_Visuals visuals { get; private set; }
    public Enemy_Health health { get; private set; }
    public Ragdoll ragdoll { get; private set; }

    protected virtual void Awake()
    {
        stateMachine = new EnemyStateMachine();

        health = GetComponent<Enemy_Health>();
        ragdoll = GetComponent<Ragdoll>();
        visuals = GetComponent<Enemy_Visuals>();
        agent = GetComponent<NavMeshAgent>();
        anim = GetComponentInChildren<Animator>();
        player = GameObject.Find("Player").GetComponent<Transform>();
    }

    protected virtual void Start()
    {
        InitializePatrolPoints();

        // Null check for healthBar before using it
        if (healthBar != null && health != null)
        {
            healthBar.maxValue = health.maxHealth;
            healthBar.value = health.CurrentHealth;
        }
    }

    protected virtual void Update()
    {
        if (ShouldEnterBattleMode())
            EnterBattleMode();
    }

    protected virtual void InitializePerk() { }

    protected bool ShouldEnterBattleMode()
    {
        if (IsPlayerInAgrresionRange() && !inBattleMode)
        {
            EnterBattleMode();
            return true;
        }
        return false;
    }

    public virtual void EnterBattleMode()
    {
        inBattleMode = true;
    }

    public virtual void GetHit(int damage)
    {
        health.ReduceHealth(damage);

        // Null check for healthBar before using it
        if (healthBar != null && health != null)
            healthBar.value = health.CurrentHealth;

        if (health.ShouldDie())
            Die();

        EnterBattleMode();
    }

    public virtual void Die() { }

    public virtual void MeleeAttackCheck(Transform[] damagePoints, float attackCheckRadius, GameObject fx, int damage)
    {
        if (!isMeleeAttackReady)
            return;

        foreach (Transform attackPoint in damagePoints)
        {
            Collider[] detectedHits = Physics.OverlapSphere(attackPoint.position, attackCheckRadius, whatIsPlayer);

            for (int i = 0; i < detectedHits.Length; i++)
            {
                IDamagable damagable = detectedHits[i].GetComponent<IDamagable>();

                if (damagable != null)
                {
                    damagable.TakeDamage(damage);
                    isMeleeAttackReady = false;
                    GameObject newAttackFx = ObjectPool.instance.GetObject(fx, attackPoint);
                    ObjectPool.instance.ReturnObject(newAttackFx, 1);
                    return;
                }
            }
        }
    }

    public void EnableMeleeAttackCheck(bool enable) => isMeleeAttackReady = enable;

    public virtual void BulletImpact(Vector3 force, Vector3 hitPoint, Rigidbody rb)
    {
        if (health.ShouldDie())
            StartCoroutine(DeathImpactCourutine(force, hitPoint, rb));
    }

    private IEnumerator DeathImpactCourutine(Vector3 force, Vector3 hitPoint, Rigidbody rb)
    {
        yield return new WaitForSeconds(.1f);
        rb.AddForceAtPosition(force, hitPoint, ForceMode.Impulse);
    }

    public void FaceTarget(Vector3 targetPosition, float rotationSpeed = 10f)
    {
        Vector3 direction = (targetPosition - transform.position).normalized;
        if (direction == Vector3.zero) return;

        Quaternion lookRotation = Quaternion.LookRotation(direction);
        transform.rotation = Quaternion.Slerp(transform.rotation, lookRotation, Time.deltaTime * rotationSpeed);
    }

    #region Animation events
    public void ActivateManualMovement(bool manualMovement) => this.manualMovement = manualMovement;
    public bool ManualMovementActive() => manualMovement;

    public void ActivateManualRotation(bool manualRotation) => this.manualRotation = manualRotation;
    public bool ManualRotationActive() => manualRotation;
    public void AnimationTrigger() => stateMachine.currentState.AnimationTrigger();

    public virtual void AbilityTrigger()
    {
        stateMachine.currentState.AbilityTrigger();
    }
    #endregion

    #region Patrol logic
    public Vector3 GetPatrolDestination()
    {
        Vector3 destination = patrolPointsPosition[currentPatrolIndex];

        currentPatrolIndex++;
        if (currentPatrolIndex >= patrolPoints.Length)
            currentPatrolIndex = 0;

        return destination;
    }

    private void InitializePatrolPoints()
    {
        patrolPointsPosition = new Vector3[patrolPoints.Length];

        for (int i = 0; i < patrolPoints.Length; i++)
        {
            patrolPointsPosition[i] = patrolPoints[i].position;
            patrolPoints[i].gameObject.SetActive(false);
        }
    }
    #endregion

    public bool IsPlayerInAgrresionRange() => Vector3.Distance(transform.position, player.position) < aggresionRange;

    protected virtual void OnDrawGizmos()
    {
        Gizmos.DrawWireSphere(transform.position, aggresionRange);
    }
}
