using UnityEngine;
using UnityEngine.UI; // NEW: Add this for UI components

public class Player : MonoBehaviour
{
    [Header("Health Bar")] // NEW: Add health bar section
    public Slider healthBar;
    [Space]

    public Transform playerBody;

    public PlayerControls controls { get; private set; }
    public Player_AimController aim { get; private set; }
    public Player_Movement movement { get; private set; }
    public Player_WeaponController weapon { get; private set; }
    public Player_WeaponVisuals weaponVisuals { get; private set; }
    public Player_Interaction interaction { get; private set; }
    public Player_Health health { get; private set; }
    public Player_AbilityController abilities { get; private set; }
    public Ragdoll ragdoll { get; private set; }

    public Animator anim { get; private set; }

    private void Awake()
    {
        controls = new PlayerControls();

        // Initialize components first
        anim = GetComponentInChildren<Animator>();
        ragdoll = GetComponent<Ragdoll>();
        health = GetComponent<Player_Health>();
        movement = GetComponent<Player_Movement>();
        aim = GetComponent<Player_AimController>();
        weapon = GetComponent<Player_WeaponController>();
        weaponVisuals = GetComponent<Player_WeaponVisuals>();
        interaction = GetComponent<Player_Interaction>();
        abilities = GetComponent<Player_AbilityController>();

        if (playerBody == null)
        {
            playerBody = transform;
            Debug.LogWarning("Player: playerBody not assigned, defaulting to self transform.");
        }

        // Optional: Warn if any critical component is missing
        if (anim == null) Debug.LogWarning("Player: Animator not found.");
        if (ragdoll == null) Debug.LogWarning("Player: Ragdoll not found.");
        if (health == null) Debug.LogWarning("Player: Player_Health not found.");
        if (movement == null) Debug.LogWarning("Player: Player_Movement not found.");
        if (abilities == null) Debug.LogWarning("Player: Player_AbilityController not found.");
    }

    // NEW: Add Start method for health bar initialization
    private void Start()
    {
        // Initialize health bar (same as enemy approach)
        if (healthBar != null && health != null)
        {
            healthBar.maxValue = health.maxHealth;
            healthBar.value = health.currentHealth;
        }
    }

    private void OnEnable()
    {
        controls.Enable();
    }

    private void OnDisable()
    {
        controls.Disable();
    }
}