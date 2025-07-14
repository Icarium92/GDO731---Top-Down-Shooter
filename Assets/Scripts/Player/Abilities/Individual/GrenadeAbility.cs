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
    private Player_Movement movement;
    private Player_Health health;
    private Camera playerCamera;
    private bool isCharging = false;
    private bool showingTrajectory = false;

    public int GrenadesRemaining => currentGrenades;
    public GrenadeAbility(AbilityData data, Player player) : base(data, player)
    {
        movement = player.movement;
        health = player.health;
        playerCamera = Camera.main;
        currentGrenades = maxGrenades;
        // Create trajectory line renderer
        //CreateTrajectoryLine();
    }

    protected override bool MeetsActivationConditions()
    {
        return !isCharging &&
        currentGrenades > 0 &&
        health != null && !health.isDead &&
        movement != null;
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
        }
    }
    protected override void OnAbilityComplete()
    {
        if (isCharging)
        {
            ThrowGrenade();
        }
        isCharging = false;
        HideTrajectoryPreview();
    }
    private void CreateTrajectoryLine()
    {
        GameObject lineObj = new GameObject("GrenadeTrajectory");
        lineObj.transform.SetParent(player.transform);
        trajectoryLine = lineObj.AddComponent<LineRenderer>();
        trajectoryLine.material = new Material(Shader.Find("Sprites/Default"));
        //trajectoryLine.color = Color.red;
        trajectoryLine.startWidth = 0.1f;
        trajectoryLine.endWidth = 0.05f;
        trajectoryLine.positionCount = trajectoryPoints;
        trajectoryLine.enabled = false;
    }

    private void StartCharging()
    {
        isCharging = true;
        chargeTime = 0f;
        showingTrajectory = true;
        if (trajectoryLine != null)
            trajectoryLine.enabled = true;
    }

    private void HandleCharging()
    {
        chargeTime += Time.deltaTime;
        chargeTime = Mathf.Clamp(chargeTime, 0f, maxChargeTime);
    }

    private void UpdateTrajectoryPreview()
    {
        if (!showingTrajectory || trajectoryLine == null) return;
        Vector3 startPos = player.transform.position + Vector3.up * 1.5f;
        Vector3 throwDirection = playerCamera.transform.forward;
        float currentForce = Mathf.Lerp(throwForce, maxThrowForce, chargeTime / maxChargeTime);
        Vector3 velocity = throwDirection * currentForce;
        // Calculate trajectory points
        for (int i = 0; i < trajectoryPoints; i++)
        {
            float time = i * timeStep;
            Vector3 point = startPos + velocity * time + 0.5f * Physics.gravity * time;//might need amending 
            trajectoryLine.SetPosition(i, point);
        }
    }

    private void ThrowGrenade()
    {
        Vector3 throwPosition = player.transform.position + Vector3.up * 1.5f;
        Vector3 throwDirection = playerCamera.transform.forward;
        float finalForce = Mathf.Lerp(throwForce, maxThrowForce, chargeTime / maxChargeTime);

        //Spawn Grenade Prefab

        if (Data.activationEffectPrefab != null)
        {
            GameObject grenade = Object.Instantiate(Data.activationEffectPrefab, throwPosition, Quaternion.identity);
            Rigidbody grenadeRb = grenade.GetComponent<Rigidbody>();
            if (grenadeRb != null)
            {
                grenadeRb.linearVelocity = throwDirection * finalForce;
            }
        }

        currentGrenades--;
        chargeTime = 0f;
    }
    private void HideTrajectoryPreview()
    {
        showingTrajectory = false;
        if (trajectoryLine != null)
            trajectoryLine.enabled = false;
    }
    public void RefillGrenades()
    {
        currentGrenades = maxGrenades;
    }

}
