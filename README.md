# Fighting classes and loadouts

A beginner-friendly class and ability system for a Roblox fighting game, in the style of a Dragon Ball arena fighter with a DC Universe Online style loadout. Characters are normal R15 rigs. You build the moves in this repo and sync them into Roblox Studio with Rojo.

There are **6 classes**. Each class has a pool of **8 moves and 2 ultimates**. You equip 4 moves and 1 ultimate. The first time someone joins they pick a class. After that they can change class from the menu only while they are out of combat.

Numbers and the “who beats whom” notes are in [BALANCE.md](BALANCE.md).

## What you can do in a match

| Key | Action |
| --- | --- |
| Click | 4-hit basic combo. The 4th hit knocks back harder. |
| Shift | Short dash with afterimages. Speedster dashes are still longer. |
| 1 2 3 4 | Cast the ability in that slot |
| Q | Cast the ultimate (only an ultimate can sit in this slot) |
| L | Open or close the loadout menu |
| F (hold) | Block. Blocked hits deal 35% damage. |
| R | Parry. A hit during the short window deals no damage and stuns the attacker. |
| Attack / Dash buttons | Same as click and Shift, for phones. |
| Block / Parry buttons | Same as F and R. |
| Rise / Drop | Show up when Flight is equipped. Space and Ctrl do the same on a keyboard. |

The HUD is a dark glass panel: health, ki, then five slots. A slot on cooldown has a dark sweep and a white hand. Hover a move in the loadout for its description. Drag it onto a slot, or click it and then click the slot.

Slots 1–4 take any non-ultimate from that class. Q takes one of the two ultimates. The same move cannot sit in two slots. The server checks this again before it saves.

The class screen covers the game until a class is chosen. **Change class** in the loadout menu opens it again. The server says no if you are still in combat (about 8 seconds after a hit or a cast).

Colored outlines on a character:

| Color | Meaning |
| --- | --- |
| Blue | Blocking |
| Orange | Super-armor (stuns, knockback, and flight knockdown bounce off; damage still lands) |
| White | Invincible for a moment |
| Red | Flying |
| Purple | Stunned (cannot cast, cannot move) |
| Cyan | Damage buff (Power Aura) |

## Classes

| Class | Fantasy |
| --- | --- |
| Ki Warrior | Blasts, a beam, a short step, an aura that buffs your damage. |
| Brawler | Punches, a grab, slams, super-armor. |
| Speedster | Dashes, a teleport hit, a flurry, a short invincible window. |
| Elemental | Fire, ice, and lightning. Slows, a stun, and area attacks. |
| Ninja | Throwing stars, a log dodge, a clone that dies in one hit, blinks. |
| Superhero | Eye beams, flight, a heavy punch, a dive. Expensive and bursty. |

Each class’s starter loadout is the first four moves you see plus the ultimate. The other move is in the menu so you can swap it in. Full numbers and counterplay are in [BALANCE.md](BALANCE.md).

## Pull the repo and sync it into Studio

You need Git, Roblox Studio, and Rojo 7. This repo pins Rojo **7.7.1** in both `rokit.toml` and `aftman.toml`. Use whichever installer you already have.

Rojo syncs a folder named **FightingClasses** into ReplicatedStorage, ServerScriptService, StarterPlayerScripts, and StarterGui. Your other scripts, maps, and tools stay where they are. Rojo will only create or update that folder. Edit the Lua files in this repo. If you edit inside the FightingClasses folder in Studio while Rojo is connected, the next sync can overwrite those edits.

### Install Rojo with Rokit

Rokit is the current installer. Download it from [github.com/rojo-rbx/rokit](https://github.com/rojo-rbx/rokit), then in this folder:

```bash
git clone https://github.com/yankingmonkey/Roblox-fighting-game.git
cd Roblox-fighting-game
rokit install
rojo serve
```

Already cloned? `git pull` inside the folder, then `rojo serve` again.

### Install Rojo with Aftman

Same Rojo version, older installer. [github.com/LPGhatguy/aftman](https://github.com/LPGhatguy/aftman), then `aftman install` instead of `rokit install`. The rest is the same.

### Connect Studio

1. Leave `rojo serve` running. It prints a port (the default is 34872).
2. In Roblox Studio, install the **Rojo** plugin (Creator Store, or the `Rojo.rbxm` file on the Rojo GitHub releases). Plugin 7.7 works with this server.
3. Open **your** place. You do not have to replace the place file.
4. Click the Rojo plugin, then **Connect**.
5. Press Play. Pick a class. Press 1.

To build a place file instead of live-syncing:

```bash
rojo build -o game.rbxlx
```

Open `game.rbxlx` in Studio. Do not commit that file. It is listed in `.gitignore`.

`rojo sourcemap default.project.json -o sourcemap.json` writes a sourcemap if your editor’s Luau plugin asks for one. That file is gitignored too.

## Prompt you can paste into Claude Code

Paste this on the PC where you use Roblox Studio. Change the folder path if you want the repo somewhere else.

```text
You are working on my Roblox fighting game on this PC. The class and ability system is the git repo https://github.com/yankingmonkey/Roblox-fighting-game on the main branch.

Please:
1. Clone that repo if it is not on this machine yet, or run git pull if it is. Use a folder I can find, and tell me the path.
2. Install Rojo 7.7.1 from the repo: run `rokit install` (uses rokit.toml) or `aftman install` (uses aftman.toml).
3. Start `rojo serve` in the repo and leave it running.
4. Tell me the exact Studio clicks: open my existing place, install the Rojo plugin if I do not have it, press Connect, then press Play.
5. Do not rewrite the ability system, the VFX themes, or the procedural poses, and do not delete my other scripts. Rojo only syncs a FightingClasses folder into ReplicatedStorage, ServerScriptService, StarterPlayerScripts, and StarterGui.
6. After it syncs, help me playtest: pick a class, click a 4-hit combo, Shift-dash, open the loadout with L, drag a different move onto a slot, and try keys 1, 2, 3, 4, and Q.
7. If I want a new move, follow README.md “Add an ability”. Keep the numbers in src/ReplicatedStorage/Shared/Balance.lua. To use my uploaded R15 animations, paste ids into src/ReplicatedStorage/Shared/AnimationConfig.lua.

The place uses R15 characters. The game is a fighting game. Do not replace my map.
```

## Saving

Class and loadout are stored with `DataStoreService` under the name `ClassLoadout_v1`. The server keeps a session copy, saves when you change class, saves again about every 20 seconds if the loadout changed, saves when you leave, and saves everyone on `BindToClose`. Loads and saves are wrapped in `pcall` and retried a few times.

In Studio, saving fails until you turn on **Game Settings → Security → Enable Studio Access to API Services** and the place is published. When that is off, the game warns once in the output and keeps going. Your class still works until you stop the playtest; it just will not be there next time. A published game saves normally.

## Add an ability

Example: a second Ki Warrior projectile called Star Dart.

1. Open `src/ReplicatedStorage/Shared/Balance.lua`.
2. Inside `Abilities`, add a key with the same name you will use as the id:

```lua
StarDart = {
    damage = 14,
    cooldown = 5,
    energyCost = 10,
    range = 80,
    speed = 160,
    radius = 2,
    knockback = 8,
},
```

3. Copy `src/ReplicatedStorage/Abilities/KiWarrior/EnergyBolt.lua` to `StarDart.lua` in the same folder.
4. Change `id`, `name`, `description`, `sortOrder`, and `color`. Point `stats` at `Balance.Abilities.StarDart`.
5. Set `Execute` to the behavior you want. The name in quotes is a function on the server in `AbilityFx.lua`:

| Call | What it does |
| --- | --- |
| `Projectile` | One or more shots. Uses `projectiles` and `spreadDeg` if you set them. |
| `Beam` | One hitscan beam. Stops at a wall or a person. |
| `ChannelBeam` | Several beam ticks. A stun cancels the rest. Set `ticks` and `tickInterval`. `sweepDegrees` makes it sweep. |
| `Melee` | A box in front of the character. |
| `Flurry` | Several melee hits. Use `hitDamage` and `hits`. |
| `Aoe` | A ball around the character (`radius`). |
| `Cone` | A long box in front (`range` and `width`). |
| `Dash` | Blink. `dodge = true` hops backward or along the move keys. `wall = true` steps up a wall. `leaveLog = true` drops a log. `iframe` and `damage` are optional. |
| `Buff` | Aura, super-armor, damage reduction, or invincibility. Whichever fields you set. |
| `ToggleFlight` | On / off. Drain is `energyPerSecond` on the Flight entry (the Superhero one). |
| `DiveBomb` | Big damage in the air (`airDamage`), small damage on the ground. |
| `ShadowClone` | A decoy that walks and punches. Any damaging hit destroys it. |
| `CloneRush` | Several charging clones. A hit destroys that clone before it connects. |

6. Add the id string to that class in `src/ReplicatedStorage/Shared/Classes.lua`, in `abilityOrder`. Put it in `defaultLoadout` only if new players should start with it equipped (five ids, ultimate last).
7. Stop Play, let Rojo sync, and play again.

`isUltimate = true` means the move can only be placed on Q. Each class should keep at least one ultimate.

The server is the one that applies damage. The client plays the neon effect immediately, then throws it away if the server says the cast was illegal (stunned, no energy, on cooldown, wrong class, empty slot).

## Add a class

1. Add a new entry to the list in `Classes.lua` with a unique `id`, a display name, a one-line summary, a color, six ability ids, and a `defaultLoadout` of five ids.
2. Create `src/ReplicatedStorage/Abilities/<YourClassId>/` and put six ability modules in it. `classId` inside each module must match the folder and the class id.
3. Add their numbers under `Balance.Abilities`.
4. Play. The class screen builds the card from `Classes.lua` and from the modules. You do not have to edit the UI code unless you want a new layout.

## Looks and poses

Effects are drawn on every client from `Controllers/VfxThemes.lua` (lightning, ki orbs, fire, ice, smoke, spinning stars, eye beams, shockwaves). They use neon parts, Beams, Trails, lights, and Roblox’s built-in particle textures. Hits also spark and shake the camera.

Bodies pose in code (`Controllers/ProceduralAnim.lua`): a fight idle, punches, a kick, casts, a dash lean, a superman flight pose, hit reacts, and a short knockdown. You do not have to upload anything for that.

## Where to put animation ids

Two places:

1. One move’s own clip, on the ability module:

```lua
animationId = "rbxassetid://1234567890",
```

Leave it `""` and the procedural pose is used.

2. Your R15 pack, for the shared poses (idle, the four combo hits, dash, flight, hit, knockback). Open `src/ReplicatedStorage/Shared/AnimationConfig.lua` and paste ids into `Overrides`. An empty string keeps the procedural pose. A filled id is played by the server so other players see it.

## Block, parry, stun, and the hooks

Damage from every ability goes through `CombatService.ApplyDamage` on the server. Hit checks use `GetPartBoundsInBox`, `GetPartsInPart`, `GetPartBoundsInRadius`, and raycasts. Nothing uses `Touched`.

The attributes on the **character** are the hooks. Your own combat code can set them, and this system will respect them:

| Attribute | Set it to | Effect |
| --- | --- | --- |
| `Blocking` | `true` while the shield is up | Hits deal `BlockDamageMultiplier` (default 35%). Ignored while `Flying` is true. |
| `ParryWindow` | `true` for a fraction of a second | The next hit deals 0, the window closes, and the attacker is stunned unless they have super-armor. |
| `Stunned` | `true` | The character cannot cast. This system also sets it for grabs, lightning, landings, and knockdowns. |
| `IFrames` | `true` | Damage is ignored completely. |
| `SuperArmor` | `true` | Stuns, knockback, and the flight knockdown are ignored. Damage and slows still apply. |
| `DamageReduction` | `0` to `0.75` | Fraction removed before block. `0.4` means 40% less. |
| `DamageBuff` | `1.25` and so on | Multiplies damage this character deals. |
| `Flying` | `true` | The flight controller lifts them. They cannot block. A damaging hit or a stun knocks them down. |
| `MoveSpeedMultiplier` | number | The client sets WalkSpeed from this. Stuns write `0`. |

F and R in this repo are a small starter so you can see the hooks without writing anything else. They ask the server to set `Blocking` and `ParryWindow`. If you already have a block or parry system:

1. Delete the F / R handling in `StarterPlayerScripts/FightingClasses/Controllers/InputController.lua`.
2. Delete the Block and Parry buttons in `UI/Hotbar.lua` if you do not want them.
3. From your system, on the server, set `Blocking` and `ParryWindow` on the character yourself.
4. Leave `CombatService.ApplyDamage` as the place that reads them. The comments at the top of that file mark the exact checks.

`Balance.BlockPreventsCasting` is `false`. Set it to `true` if holding block should also stop abilities.

Energy is a player attribute, `Energy` and `MaxEnergy`, so the bar does not flicker on respawn. By default respawn refills energy and sets health to `PlayerHealth`. If your game already sets health, set `OverrideHealth = false` in `Balance.lua`.

## Project layout

```text
default.project.json          Rojo 7 project
rokit.toml / aftman.toml      Pins Rojo 7.7.1
src/ReplicatedStorage/
  Shared/                     Balance, classes, loadout rules, registry
  Abilities/<Class>/<Ability> One ModuleScript per move
src/ServerScriptService/
  Main.server.lua             Starts the services and the remotes
  Services/                   Data, energy, combat, hitboxes, ability cast checks
src/StarterPlayer/StarterPlayerScripts/
  Main.client.lua             HUD, keys, flight, VFX
  Controllers/                Input, prediction, movement, neon effects
  UI/                         Class screen, loadout, hotbar
src/StarterGui/               Placeholder so Rojo has a StarterGui folder
BALANCE.md                    Numbers and counterplay
```

There are two remotes, both created by the server under `ReplicatedStorage.Remotes`:

- `Action` — client to server. Cast, set class, set loadout, block, parry.
- `Notify` — server to client. Cast yes/no, VFX for other players, menu errors.

The client never sends a damage number. The server checks the class, the slot, the cooldown, the energy, the stun, and a rate limit, then runs `Execute`.

## Limits to know about

- Movement (dash, blink, dive, flight) is applied on your client because you own your character. The server recomputes the dash from your aim and scores the hitbox itself. A cheater can still move their body; they cannot choose the damage.
- Clones are simple neon dummies with a name tag, not copies of the avatar. Any damaging hit destroys one. Your own attacks do not destroy your own clone.
- There is no team system. Everyone can hit everyone.
- There is no combo string, lock-on, or animation set yet. Animations play once you fill in `animationId`.
- Channel beams spend their energy up front. A stun still cancels the remaining ticks.
- DataStore writes are a simple save of the latest session. Two servers editing the same player at once can overwrite each other.
- The placeholder effects are neon parts, a Beam, and a ParticleEmitter using Roblox’s built-in sparkle texture. They are cleaned up with `Debris`.
- The backpack hotbar is turned off so it does not cover this one. Remove that call in `Main.client.lua` if you want the backpack back.
