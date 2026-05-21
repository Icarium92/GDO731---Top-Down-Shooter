# Glitchslinger

A top-down arena shooter built in Unity for the **GDO731** module on the **MA Indie Game Development** at Falmouth University.

> *Fight. Swap. Survive.*

Glitchslinger is a wave-based combat game built around momentum, weapon variety, and aggressive play. The player moves through an arena, collects and swaps weapons, fights escalating enemy waves, and earns style points for staying in the fight.

This was a 5-person university group project focused on building a complete, playable game within the module timeframe. My main contributions were in gameplay systems, combat implementation, enemy behaviour, UI integration, and technical design.

---

## About the Project

The brief for this project was to build a complete, playable game within the module timeframe. As a team, we used the project to explore fast-paced arena combat, modular gameplay systems, and a more data-driven approach to weapons, enemies, waves, and abilities.

Glitchslinger was a learning project, so some systems and implementation approaches were influenced by tutorials, Unity documentation, course materials, online examples, and common Unity design patterns. My work focused on adapting those ideas, extending them, connecting them with the rest of the project, and helping shape them into a cohesive playable game.

The style system came relatively late in development, initially as a score multiplier, but it became more interesting once it started shaping how the player approached fights. Encouraging aggression rather than passive play changed how the AI needed to behave in response, which pushed us to add more variety to enemy encounter design.

The most time-consuming part of my work was enemy behaviour and combat integration. Rather than relying only on separate bespoke controllers, I worked with a shared state-based structure that could support melee, ranged, shield, axe, and boss variants with different behaviours layered on top. That decision helped with iteration, even if the upfront cost was high.

---

## Gameplay Systems

My contributions included work across several core systems:

- **Player controller**: CharacterController-based movement with mouse aiming, movement locking, ragdoll death, and audio feedback
- **Weapon system**: pistol, revolver, auto-rifle, shotgun, and rifle; including pickups, inventory slots, reload logic, spread, burst fire, and a rifle-specific charged shot
- **Ability system**: dash, grenade, trap, and heavy attack, each with cooldowns, input handling, and visual feedback; built around shared ability logic and ScriptableObject configuration
- **Style system**: score-based combat layer with combo windows, style decay, named style ranks, and multipliers that reward staying in the fight
- **Enemy AI**: shared finite state machine approach across melee, ranged, dodge, shield, axe-throw, and boss variants; ranged enemies use cover seeking, grenade throws, and line-of-sight checks
- **Boss encounters**: two boss types, flamethrower and hammer, with distinct attack patterns, wave interruption, and dedicated states for jump attacks and area damage
- **Wave system**: enemy spawning, scaling, and boss waves driven by ScriptableObject wave data
- **Object pooling**: reusable pooling for bullets, impact effects, pickups, and enemies to support high-volume combat
- **UI system**: health, ammo, weapon slots, ability cooldowns, style level, score, pause, death, and stage-clear interfaces
- **Camera system**: Cinemachine top-down camera with weapon-aware framing
- **Audio**: gunshots, footsteps, reloads, explosions, ability effects, and combat feedback through a centralised audio manager

---

## Built With

- **Unity 6000.0.37f1 (URP)**: Universal Render Pipeline, 3D
- **C#**
- **Input System**: Unity's new input system
- **Cinemachine**: camera framing
- **AI Navigation / NavMesh**: enemy pathfinding
- **Animation Rigging**: IK constraints for weapon alignment
- **TextMeshPro**: UI text
- **ScriptableObjects**: weapons, abilities, waves, and event system

---

## Credits

Glitchslinger was developed as a university group learning project. Some systems, patterns, and implementation approaches were influenced by Unity documentation, tutorials, course materials, online examples, and common Unity development practices.

| Asset / Tool | Source |
|---|---|
| Unity packages (URP, Cinemachine, Input System, NavMesh, Animation Rigging, TextMeshPro) | [Unity Technologies](https://unity.com/) |
| Gameplay systems, combat implementation, enemy behaviour, UI integration, and technical design contributions | Samuel Perkins |
| Full game project | 5-person GDO731 university team |

---

## Context

This project was submitted as a module deliverable for **GDO731** on the **MA Indie Game Development** programme at Falmouth University.

It was built by a 5-person group across the module duration, covering game design, programming, combat design, AI, UI, art, audio, and production. My individual focus was on gameplay systems, combat implementation, enemy behaviour, UI integration, and technical design.
