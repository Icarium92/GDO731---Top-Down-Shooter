using UnityEngine;
using System.Collections;

public class TrapAbility : BaseAbility
{
    [Header("Trap Settings")]
    private int maxTraps = 2;
    private int currentTraps;
    private float placementRange = 3f;
    private float trapLifetime = 30f;
    private LayerMask groundLayers = 1;
    private LayerMask obstacleCheck = -1;

    [Header("Placement Indicator")]
    private GameObject placementIndicator;
    private Material indicatorMaterial;
    private bool showingPlacement = false;

    private StyleSystem styleSystem;
    private Camera playerCamera;
    private Player_Movement movement;
    private Player_Health health;

    public int TrapsRemaining => currentTraps;
    public bool IsPlacing => showingPlacement;

    public TrapAbility(AbilityData data, Player player) : base(data, player)
    {
        currentTraps = maxTraps;
        styleSystem = player.styleSystem;
        movement = player.movement;
        health = player.health;

        playerCamera = Camera.main;
        if (playerCamera == null)
            playerCamera = Object.FindFirstObjectByType<Camera>();

        CreatePlacementIndicator();
    }

    protected override bool MeetsActivationConditions()
    {
        return currentTraps > 0 && !IsPlayerDead() && movement != null;
    }

    private bool IsPlayerDead()
    {
        return health != null && health.currentHealth <= 0;
    }

    protected override void OnAbilityExecute()
    {
        StartPlacement();
    }

    protected override void UpdateAbilityLogic()
    {
        if (showingPlacement)
        {
            UpdatePlacementIndicator();

            if (Input.GetMouseButtonDown(0))
            {
                CompleteAbility();
            }
            else if (Input.GetKeyDown(KeyCode.T) || Input.GetKeyDown(KeyCode.Escape))
            {
                CancelPlacement();
            }
        }
    }

    protected override void OnAbilityComplete()
    {
        if (showingPlacement)
        {
            PlaceTrap();
            EndPlacement();
        }
    }

    private void CreatePlacementIndicator()
    {
        placementIndicator = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        placementIndicator.name = "TrapPlacementIndicator";

        Object.Destroy(placementIndicator.GetComponent<Collider>());

        indicatorMaterial = new Material(Shader.Find("Standard"));
        indicatorMaterial.color = new Color(1f, 0f, 0f, 0.3f);
        indicatorMaterial.SetFloat("_Mode", 3);
        indicatorMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        indicatorMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        indicatorMaterial.SetInt("_ZWrite", 0);
        indicatorMaterial.DisableKeyword("_ALPHATEST_ON");
        indicatorMaterial.EnableKeyword("_ALPHABLEND_ON");
        indicatorMaterial.DisableKeyword("_ALPHAPREMULTIPLY_ON");
        indicatorMaterial.renderQueue = 3000;

        placementIndicator.GetComponent<Renderer>().material = indicatorMaterial;
        placementIndicator.transform.localScale = new Vector3(2f, 0.1f, 2f);
        placementIndicator.SetActive(false);
    }

    private void StartPlacement()
    {
        showingPlacement = true;
        if (placementIndicator != null)
        {
            placementIndicator.SetActive(true);
        }
    }

    private void UpdatePlacementIndicator()
    {
        if (placementIndicator == null || playerCamera == null)
            return;

        Vector3 targetPosition = GetTrapPlacementPosition();
        bool canPlace = IsValidPlacementPosition(targetPosition);

        placementIndicator.transform.position = targetPosition;

        if (indicatorMaterial != null)
        {
            indicatorMaterial.color = canPlace ?
                new Color(0f, 1f, 0f, 0.3f) :
                new Color(1f, 0f, 0f, 0.3f);
        }
    }

    private void PlaceTrap()
    {
        Vector3 trapPosition = GetTrapPlacementPosition();

        if (!IsValidPlacementPosition(trapPosition))
        {
            Debug.Log("Cannot place trap at this location!");
            return;
        }

        if (data.activationEffectPrefab != null)
        {
            GameObject trap = Object.Instantiate(data.activationEffectPrefab, trapPosition, Quaternion.identity);
            SetupTrapComponent(trap);
            Object.Destroy(trap, trapLifetime);
        }
        else
        {
            CreateBasicTrap(trapPosition);
        }

        currentTraps--;

        if (styleSystem != null)
            styleSystem.OnAbilityUsed("Trap");

        StartCooldown();
    }

    private void SetupTrapComponent(GameObject trap)
    {
        var trapScript = trap.GetComponent<Trap>(); // NEW - using Trap instead
        if (trapScript != null)
        {
            trapScript.SetupTrap(75, LayerMask.GetMask("Enemy"));
        }
        else
        {
            var basicTrap = trap.AddComponent<BasicTrap>();
            basicTrap.damage = 75;
            basicTrap.targetLayers = LayerMask.GetMask("Enemy");
            basicTrap.triggerRadius = 2f;
        }
    }

    private void CreateBasicTrap(Vector3 position)
    {
        GameObject trap = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        trap.name = "PlayerTrap";
        trap.transform.position = position;
        trap.transform.localScale = new Vector3(1.5f, 0.2f, 1.5f);

        var renderer = trap.GetComponent<Renderer>();
        Material trapMat = new Material(Shader.Find("Standard"));
        trapMat.color = Color.gray;
        renderer.material = trapMat;

        var basicTrap = trap.AddComponent<BasicTrap>();
        basicTrap.damage = 75;
        basicTrap.targetLayers = LayerMask.GetMask("Enemy");
        basicTrap.triggerRadius = 2f;

        Object.Destroy(trap, trapLifetime);
    }

    private Vector3 GetTrapPlacementPosition()
    {
        if (playerCamera != null)
        {
            Ray ray = playerCamera.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(ray, out RaycastHit hit, placementRange * 2, groundLayers))
            {
                return hit.point + Vector3.up * 0.1f;
            }
        }

        return player.transform.position + player.transform.forward * 2f;
    }

    private bool IsValidPlacementPosition(Vector3 position)
    {
        float distanceToPlayer = Vector3.Distance(position, player.transform.position);
        if (distanceToPlayer > placementRange)
            return false;

        if (Physics.CheckSphere(position, 1f, obstacleCheck & ~groundLayers))
            return false;

        if (!Physics.Raycast(position + Vector3.up, Vector3.down, 2f, groundLayers))
            return false;

        return true;
    }

    private void EndPlacement()
    {
        showingPlacement = false;
        if (placementIndicator != null)
        {
            placementIndicator.SetActive(false);
        }
    }

    private void CancelPlacement()
    {
        EndPlacement();
    }

    public void RefillTraps()
    {
        currentTraps = maxTraps;
    }

    public void AddTraps(int amount)
    {
        currentTraps = Mathf.Min(currentTraps + amount, maxTraps);
    }

    public override bool CanActivate()
    {
        return base.CanActivate() && !showingPlacement;
    }
}

public class BasicTrap : MonoBehaviour
{
    public int damage = 75;
    public LayerMask targetLayers = -1;
    public float triggerRadius = 2f;
    public float armingDelay = 1f;

    private bool isArmed = false;
    private bool hasTriggered = false;
    private SphereCollider triggerCollider;

    private void Start()
    {
        triggerCollider = gameObject.AddComponent<SphereCollider>();
        triggerCollider.isTrigger = true;
        triggerCollider.radius = triggerRadius;

        Invoke(nameof(ArmTrap), armingDelay);
        StartCoroutine(ArmingIndicator());
    }

    private void ArmTrap()
    {
        isArmed = true;
    }

    private IEnumerator ArmingIndicator()
    {
        var renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            Color originalColor = renderer.material.color;

            float elapsed = 0f;
            while (elapsed < armingDelay)
            {
                renderer.material.color = Color.Lerp(originalColor, Color.red,
                    Mathf.PingPong(elapsed * 4f, 1f));
                elapsed += Time.deltaTime;
                yield return null;
            }

            renderer.material.color = Color.red;
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (!isArmed || hasTriggered)
            return;

        if (((1 << other.gameObject.layer) & targetLayers) == 0)
            return;

        TriggerTrap(other.gameObject);
    }

    private void TriggerTrap(GameObject target)
    {
        hasTriggered = true;

        var health = target.GetComponent<Enemy_Health>();
        if (health != null)
        {
            health.TakeDamage(damage);
        }

        var rb = target.GetComponent<Rigidbody>();
        if (rb != null)
        {
            Vector3 direction = (target.transform.position - transform.position).normalized;
            rb.AddForce(direction * 300f, ForceMode.Impulse);
        }

        StartCoroutine(TrapExplosionEffect());
        Destroy(gameObject, 0.5f);
    }

    private IEnumerator TrapExplosionEffect()
    {
        var renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            for (int i = 0; i < 3; i++)
            {
                renderer.material.color = Color.white;
                yield return new WaitForSeconds(0.05f);
                renderer.material.color = Color.red;
                yield return new WaitForSeconds(0.05f);
            }
        }
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = isArmed ? Color.red : Color.yellow;
        Gizmos.DrawWireSphere(transform.position, triggerRadius);
    }
}