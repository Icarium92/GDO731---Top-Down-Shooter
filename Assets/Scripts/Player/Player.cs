using UnityEngine;

public class Player : MonoBehaviour
{
    public Transform playerBody;

    public PlayerControls controls { get; private set; }
    public Player_AimController aim { get; private set; }
    public Player_Movement movement { get; private set; }
    public Player_WeaponController weapon { get; private set; }
    public Player_WeaponVisuals weaponVisuals { get; private set; }
    public Player_Interaction interaction { get; private set; }
    public Player_Health health { get; private set; }
    public Ragdoll ragdoll { get; private set; }

    public Animator anim { get; private set; }

    private void Awake()
    {
        controls = new PlayerControls();

        anim = GetComponentInChildren<Animator>();
        ragdoll = GetComponent<Ragdoll>();
        health = GetComponent<Player_Health>();
        aim = GetComponent<Player_AimController>();
        movement = GetComponent<Player_Movement>();
        weapon = GetComponent<Player_WeaponController>();
        weaponVisuals = GetComponent<Player_WeaponVisuals>();
        interaction = GetComponent<Player_Interaction>();

        if (playerBody == null)
        {
            playerBody = transform;
            Debug.LogWarning("Player: playerBody not assigned, defaulting to self transform.");
        }

        // Optional: Warn if any critical component is missing
        if (anim == null) Debug.LogWarning("Player: Animator not found.");
        if (ragdoll == null) Debug.LogWarning("Player: Ragdoll not found.");
        if (health == null) Debug.LogWarning("Player: Player_Health not found.");
        // ...add more as needed
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
