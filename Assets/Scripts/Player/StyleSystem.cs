using UnityEngine;
using UnityEngine.Events;
using System.Collections;

public class StyleSystem : MonoBehaviour
{
    [Header("Style Settings")]
    public int maxStyleLevel = 10;
    public float styleDecayRate = 1f;
    public float styleDecayDelay = 5f;
    public float comboWindow = 3f;
    public float styleMultiplierMax = 3f;

    [Header("Style Points Configuration")]
    public float baseKillPoints = 10f;
    public float headShotMultiplier = 1.5f;
    public float comboMultiplier = 1.2f;

    [Header("Style Events")]
    public UnityEvent<int> onStyleLevelChanged;
    public UnityEvent<float> onStylePointsChanged;
    public UnityEvent onStyleIncrease;
    public UnityEvent onStyleDecrease;
    public UnityEvent onStyleBoost;
    public UnityEvent<string> onStyleAction;

    [Header("Debug")]
    public bool showDebugInfo = true;

    private int currentStyleLevel = 0;
    private float stylePoints = 0f;
    private float lastStyleTime;
    private int currentCombo = 0;
    private float lastComboTime;
    private float currentMultiplier = 1f;

    private int totalKills = 0;
    private int totalAbilitiesUsed = 0;
    private float sessionTime = 0f;

    public int CurrentStyleLevel => currentStyleLevel;
    public float CurrentStylePoints => stylePoints;
    public float StyleProgress => (stylePoints % GetPointsForNextLevel()) / GetPointsForNextLevel();
    public int CurrentCombo => currentCombo;
    public float CurrentMultiplier => currentMultiplier;
    public float TimeUntilDecay => Mathf.Max(0, styleDecayDelay - (Time.time - lastStyleTime));

    private readonly string[] styleLevelNames = {
        "DULL", "DISMAL", "CRAZY", "BADASS", "APOCALYPTIC",
        "SAVAGE", "SICK", "SMOKIN'", "STYLISH", "SUPREME", "ULTRAKILL"
    };

    private void Start()
    {
        lastStyleTime = Time.time;
        lastComboTime = Time.time;
        sessionTime = 0f;

        onStyleLevelChanged?.Invoke(currentStyleLevel);
        onStylePointsChanged?.Invoke(stylePoints);
    }

    private void Update()
    {
        sessionTime += Time.deltaTime;
        HandleStyleDecay();
        HandleComboDecay();
        UpdateMultiplier();

        if (showDebugInfo)
        {
            DebugDisplay();
        }
    }

    public void OnAbilityUsed(string abilityType)
    {
        float points = GetStylePointsForAbility(abilityType);
        AddStylePoints(points);
        totalAbilitiesUsed++;

        onStyleAction?.Invoke($"Ability: {abilityType} (+{points:F0})");
        RefreshStyleTimer();
    }

    public void OnEnemyKilled(int enemiesKilled = 1, bool isHeadshot = false, string weaponType = "")
    {
        for (int i = 0; i < enemiesKilled; i++)
        {
            float points = baseKillPoints;

            if (isHeadshot)
                points *= headShotMultiplier;

            if (currentCombo > 0)
                points *= Mathf.Min(1f + (currentCombo * 0.1f), comboMultiplier);

            points *= currentMultiplier;

            AddStylePoints(points);
            IncrementCombo();
            totalKills++;

            string actionText = isHeadshot ?
                $"Headshot Kill (+{points:F0})" :
                $"Kill (+{points:F0})";

            if (currentCombo > 1)
                actionText += $" x{currentCombo} Combo";

            onStyleAction?.Invoke(actionText);
        }

        RefreshStyleTimer();
    }

    public void OnSpecialAction(string actionName, float pointMultiplier = 1f)
    {
        float points = 20f * pointMultiplier * currentMultiplier;
        AddStylePoints(points);

        onStyleAction?.Invoke($"{actionName} (+{points:F0})");
        RefreshStyleTimer();
    }

    public void ResetStyle()
    {
        stylePoints = 0f;
        currentStyleLevel = 0;
        currentCombo = 0;
        currentMultiplier = 1f;

        onStyleLevelChanged?.Invoke(currentStyleLevel);
        onStylePointsChanged?.Invoke(stylePoints);
        onStyleAction?.Invoke("Style Reset");
    }

    public string GetCurrentStyleName()
    {
        int index = Mathf.Clamp(currentStyleLevel, 0, styleLevelNames.Length - 1);
        return styleLevelNames[index];
    }

    private void AddStylePoints(float points)
    {
        stylePoints += points;
        stylePoints = Mathf.Max(0, stylePoints);

        onStylePointsChanged?.Invoke(stylePoints);
        CheckForLevelUp();
        onStyleIncrease?.Invoke();
    }

    private void CheckForLevelUp()
    {
        int targetLevel = CalculateStyleLevel();
        if (targetLevel > currentStyleLevel)
        {
            currentStyleLevel = targetLevel;
            onStyleLevelChanged?.Invoke(currentStyleLevel);

            if (targetLevel >= 7)
                onStyleBoost?.Invoke();

            onStyleAction?.Invoke($"LEVEL UP: {GetCurrentStyleName()}");
        }
        else if (targetLevel < currentStyleLevel)
        {
            currentStyleLevel = targetLevel;
            onStyleLevelChanged?.Invoke(currentStyleLevel);
        }
    }

    private void HandleStyleDecay()
    {
        if (Time.time - lastStyleTime > styleDecayDelay)
        {
            float decayAmount = styleDecayRate * Time.deltaTime;

            if (currentStyleLevel >= 7)
                decayAmount *= 0.5f;
            else if (currentStyleLevel >= 5)
                decayAmount *= 0.75f;

            stylePoints = Mathf.Max(0, stylePoints - decayAmount);
            onStylePointsChanged?.Invoke(stylePoints);

            int newLevel = CalculateStyleLevel();
            if (newLevel < currentStyleLevel)
            {
                currentStyleLevel = newLevel;
                onStyleLevelChanged?.Invoke(currentStyleLevel);
                onStyleDecrease?.Invoke();
            }
        }
    }

    private void HandleComboDecay()
    {
        if (Time.time - lastComboTime > comboWindow)
        {
            if (currentCombo > 0)
            {
                currentCombo = 0;
                onStyleAction?.Invoke("Combo Broken");
            }
        }
    }

    private void UpdateMultiplier()
    {
        float levelMultiplier = 1f + (currentStyleLevel * 0.1f);
        float comboBonus = currentCombo > 0 ? 1f + (currentCombo * 0.05f) : 1f;

        currentMultiplier = Mathf.Min(levelMultiplier * comboBonus, styleMultiplierMax);
    }

    private void IncrementCombo()
    {
        currentCombo++;
        lastComboTime = Time.time;
    }

    private void RefreshStyleTimer()
    {
        lastStyleTime = Time.time;
    }

    private int CalculateStyleLevel()
    {
        return Mathf.Min(Mathf.FloorToInt(stylePoints / GetPointsForNextLevel()), maxStyleLevel);
    }

    private float GetPointsForNextLevel()
    {
        if (currentStyleLevel == 0) return 100f;
        return 100f + (currentStyleLevel * 150f);
    }

    private float GetStylePointsForAbility(string abilityType)
    {
        float basePoints = abilityType switch
        {
            "Dash" => 15f,
            "Grenade" => 25f,
            "Trap" => 20f,
            "ChargeShot" => 30f,
            "Slide" => 10f,
            "WallRun" => 20f,
            _ => 10f
        };

        return basePoints * currentMultiplier;
    }

    private void DebugDisplay()
    {
        if (showDebugInfo && currentStyleLevel > 0)
        {
            string debugText = $"Style: {GetCurrentStyleName()} (Level {currentStyleLevel})\n";
            debugText += $"Points: {stylePoints:F0}/{GetPointsForNextLevel():F0}\n";
            debugText += $"Combo: x{currentCombo}\n";
            debugText += $"Multiplier: {currentMultiplier:F1}x";
        }
    }

    public StyleStats GetSessionStats()
    {
        return new StyleStats
        {
            totalKills = this.totalKills,
            totalAbilitiesUsed = this.totalAbilitiesUsed,
            highestStyleLevel = this.currentStyleLevel,
            totalStylePoints = this.stylePoints,
            sessionTime = this.sessionTime,
            averageStyleLevel = sessionTime > 0 ? stylePoints / sessionTime : 0f
        };
    }
}

[System.Serializable]
public struct StyleStats
{
    public int totalKills;
    public int totalAbilitiesUsed;
    public int highestStyleLevel;
    public float totalStylePoints;
    public float sessionTime;
    public float averageStyleLevel;
}