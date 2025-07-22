using UnityEngine;
using System.Collections;

public class GrenadeAbility : BaseAbility
{
    [Header("Grenade Settings")]
    private float throwForce = 15f;
    private float maxThrowForce = 25f;
    private float chargeTime = 0f;
    private float maxChargeTime = 2f;
    private int maxGrenades = 3;
    private int currentGrenades;

    [Header("Trajectory")]
    private LineRenderer trajectoryLine;
    private int trajectoryPoints = 30;
    private float timeStep = 0.1f;
    private Material trajectoryMaterial;

    private Player_Movement movement;
    private Player_Health health;
    private Camera playerCamera;
    private bool isCharging = false;
    private bool showingTrajectory = false;
    private Vector3[] trajectoryPointsArray;

    private StyleSystem styleSystem;

    public int GrenadesRemaining => currentGrenades;
    public bool IsCharging => isCharging;
    public float ChargeProgress => chargeTime / maxChargeTime;

    public GrenadeAbility(AbilityData data, Player player) : base(data, player)
    {
        movement = player.movement;
        health = player.health;
        styleSystem = player.styleSystem;

        playerCamera = Camera.main;
        if (playerCamera == null)
            playerCamera = Object.FindFirstObjectByType<Camera>();

        currentGrenades = maxGrenades;
        trajectoryPointsArray = new Vector3[trajectoryPoints];

        CreateTrajectoryLine();
    }

    protected override bool MeetsActivationConditions()
    {
        return !isCharging && currentGrenades > 0 &&
               health != null && !IsPlayerDead() &&
               movement != null;
    }

    private bool IsPlayerDead()
    {
        return health != null && health.currentHealth <= 0;
    }

    protected override void OnAbilityExecute()
    {
        StartCharging();
    }

    protected override void UpdateAbilityLogic()
    {
        if (isCharging)
        {
            HandleCharging();
            UpdateTrajectoryPreview();

            if (Input.GetKeyUp(KeyCode.G))
            {
                CompleteAbility();
            }
        }
    }

    protected override void OnAbilityComplete()
    {
        if (isCharging)
        {
            ThrowGrenade();
            isCharging = false;
            HideTrajectoryPreview();
        }
    }

    private void CreateTrajectoryLine()
    {
        GameObject trajectoryObj = new GameObject("GrenadeTrajectory");
        trajectoryObj.transform.SetParent(player.transform);

        trajectoryLine = trajectoryObj.AddComponent<LineRenderer>();
        trajectoryLine.material = CreateTrajectoryMaterial();
        trajectoryLine.startColor = Color.yellow;
        trajectoryLine.endColor = Color.yellow;
        trajectoryLine.startWidth = 0.1f;
        trajectoryLine.endWidth = 0.05f;
        trajectoryLine.positionCount = trajectoryPoints;
        trajectoryLine.useWorldSpace = true;
        trajectoryLine.enabled = false;

        trajectoryLine.sortingOrder = 10;
    }

    private Material CreateTrajectoryMaterial()
    {
        if (trajectoryMaterial == null)
        {
            trajectoryMaterial = new Material(Shader.Find("Sprites/Default"));
            trajectoryMaterial.color = Color.yellow;
        }
        return trajectoryMaterial;
    }

    private void StartCharging()
    {
        isCharging = true;
        chargeTime = 0f;
        showingTrajectory = true;

        if (trajectoryLine != null)
        {
            trajectoryLine.enabled = true;
        }
    }

    private void HandleCharging()
    {
        chargeTime += Time.deltaTime;
        chargeTime = Mathf.Clamp(chargeTime, 0f, maxChargeTime);

        if (trajectoryLine != null)
        {
            float chargePercent = chargeTime / maxChargeTime;
            trajectoryLine.startColor = Color.Lerp(Color.yellow, Color.red, chargePercent);
            trajectoryLine.endColor = Color.Lerp(Color.yellow, Color.red, chargePercent);
        }
    }

    private void UpdateTrajectoryPreview()
    {
        if (!showingTrajectory || trajectoryLine == null || playerCamera == null)
            return;

        Vector3 startPosition = GetThrowPosition();
        Vector3 throwDirection = GetThrowDirection();
        float currentForce = GetCurrentThrowForce();

        CalculateTrajectoryPoints(startPosition, throwDirection * currentForce);
        trajectoryLine.SetPositions(trajectoryPointsArray);
    }

    private void CalculateTrajectoryPoints(Vector3 startPos, Vector3 initialVelocity)
    {
        float gravity = Physics.gravity.y;

        for (int i = 0; i < trajectoryPoints; i++)
        {
            float time = i * timeStep;
            Vector3 point = startPos + initialVelocity * time;
            point.y += 0.5f * gravity * time * time;

            trajectoryPointsArray[i] = point;

            if (point.y <= 0.1f)
            {
                for (int j = i; j < trajectoryPoints; j++)
                {
                    trajectoryPointsArray[j] = new Vector3(point.x, 0.1f, point.z);
                }
                break;
            }
        }
    }

    private void ThrowGrenade()
    {
        Vector3 throwPosition = GetThrowPosition();
        Vector3 throwDirection = GetThrowDirection();
        float finalForce = GetCurrentThrowForce();

        if (data.activationEffectPrefab != null)
        {
            // Use ObjectPool.instance to get the grenade (matching your system)
            GameObject grenade = ObjectPool.instance.GetObject(data.activationEffectPrefab, null);
            grenade.transform.position = throwPosition;
            grenade.transform.rotation = Quaternion.identity;

            Rigidbody grenadeRb = grenade.GetComponent<Rigidbody>();
            if (grenadeRb != null)
            {
                grenadeRb.linearVelocity = throwDirection * finalForce;
                grenadeRb.angularVelocity = Random.insideUnitSphere * 5f;
            }

            SetupGrenadeComponent(grenade);
        }

        currentGrenades--;
        chargeTime = 0f;

        if (styleSystem != null)
            styleSystem.OnAbilityUsed("Grenade");

        StartCooldown();
    }

    private void SetupGrenadeComponent(GameObject grenade)
    {
        // Use your actual Enemy_Grenade class
        var grenadeScript = grenade.GetComponent<Enemy_Grenade>();
        if (grenadeScript != null)
        {
            // Use your actual SetupGrenade method signature
            grenadeScript.SetupGrenade(
                LayerMask.GetMask("Enemy"), // Target enemies (opposite of ally mask)
                GetTargetPosition(),        // Target position
                1f,                        // Time to target
                3f,                        // Countdown timer
                500f,                      // Impact power
                50                         // Grenade damage
            );
        }
        else
        {
            Debug.LogWarning("GrenadeAbility: No Enemy_Grenade component found on grenade prefab!");
        }
    }

    private void HideTrajectoryPreview()
    {
        showingTrajectory = false;
        if (trajectoryLine != null)
        {
            trajectoryLine.enabled = false;
        }
    }

    private Vector3 GetThrowPosition()
    {
        return player.transform.position + Vector3.up * 1.5f + player.transform.forward * 0.5f;
    }

    private Vector3 GetThrowDirection()
    {
        if (playerCamera != null)
            return playerCamera.transform.forward;
        return player.transform.forward;
    }

    private float GetCurrentThrowForce()
    {
        return Mathf.Lerp(throwForce, maxThrowForce, chargeTime / maxChargeTime);
    }

    private Vector3 GetTargetPosition()
    {
        if (playerCamera != null)
        {
            Ray ray = playerCamera.ScreenPointToRay(new Vector3(Screen.width / 2, Screen.height / 2, 0));
            if (Physics.Raycast(ray, out RaycastHit hit, 100f))
                return hit.point;
        }
        return player.transform.position + player.transform.forward * 15f;
    }

    public void RefillGrenades()
    {
        currentGrenades = maxGrenades;
    }

    public void AddGrenades(int amount)
    {
        currentGrenades = Mathf.Min(currentGrenades + amount, maxGrenades);
    }

    public void CancelCharge()
    {
        if (isCharging)
        {
            isCharging = false;
            HideTrajectoryPreview();
        }
    }

    public override bool CanActivate()
    {
        return base.CanActivate() && !isCharging;
    }
}