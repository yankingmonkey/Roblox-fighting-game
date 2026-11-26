# Balance

All of the numbers live in `src/ReplicatedStorage/Shared/Balance.lua`. Change them there, stop the playtest, and play again. Ability modules copy the headline damage, cooldown, energy, and range so the menus stay in sync. Do not hard-code a second copy in the ability file.

These notes assume a character has **100 health** (`PlayerHealth`) and **100 energy** (`MaxEnergy`). Damage below is before block, aura, or Iron Body.

## Shared rules

| Rule | Value | What it means |
| --- | --- | --- |
| Health | 100 | About four to six solid hits, or one big combo plus an ultimate. |
| Energy regen in combat | 5 / second | You cannot hold every button down. |
| Energy regen out of combat | 12 / second | The bar refills between fights. |
| Combat timer | 8 seconds | Dealing damage, taking damage, or casting keeps you in combat. Class changes wait until it ends. |
| Block | 35% damage | Set `Blocking` on the character. Works on melee, projectiles, beams, and ultimates. |
| Global cast gap | 0.15 seconds | Stops a client from firing every slot in one frame. |
| Parry window | 0.18 seconds | A hit during it deals 0 and stuns the attacker for 0.6 seconds. |
| Flight drain | 12 / second | Flight replaces regen. From a full bar that is about 8 seconds in the air. |
| Flight knockdown | 0.35 second stun | Any damaging hit (or a stun) drops a flyer who does not have super-armor. |

Blocked damage is `hit * 0.35`. A 60 damage beam becomes 21 if they are blocking. Beams are **not** unblockable.

## How to read a class

Practical damage is lower than the "if every hit lands on cooldown" number, because energy regen in combat is only 5 per second and people miss. The classes are aimed at the same fight length, with different jobs:

| Class | Practical damage | Burst | Mobility | Defense | Sustain |
| --- | --- | --- | --- | --- | --- |
| Ki Warrior | Steady ranged | Medium (aura + beam, or the ultimate) | Short step | Low | High. Energy Bolt is cheap. |
| Brawler | High if they are touching you | High | Low (one charge) | Highest. Super-armor and, if equipped, Iron Body | Medium. They have to walk in. |
| Speedster | Medium | Medium (the flurry) | Highest | Low, but with short invincible windows | Medium. Dashes cost energy. |
| Elemental | Medium on one target, better on a group | Medium | Low | Low | Medium. Slows buy time. |
| Ninja | Medium if the stars land | Medium | High | Medium. Log Swap and a clone that eats a hit | Medium. |
| Superhero | Low if they fly or miss, high if the beam lands | Highest single button | High while flying | Low in the air, ordinary on the ground | Lowest. The beam and flight empty the bar. |

Nobody's basic rotation deletes a 100 health target in one second. Superhero is the exception **if** Thermal Gaze is not blocked, stunned, or aimed at a wall: 60 damage in 1.25 seconds, then the bar is empty.

## Ki Warrior

Ranged. Default slots: Energy Bolt, Piercing Beam, Energy Step, Power Aura, ultimate Nova Sphere.

| Ability | Damage | Cooldown | Energy | Notes |
| --- | --- | --- | --- | --- |
| Energy Bolt | 18 | 4s | 12 | Fast projectile. The efficient button. |
| Volley Shot | 8 x 3 = 24 | 8s | 18 | Spread. Easy to block or sidestep one of them. |
| Piercing Beam | 28 | 10s | 22 | Stops at the first body or wall. Blockable. |
| Power Aura | 0, +25% damage for 6s | 16s | 16 | Multiplies later hits, including the ultimate. |
| Energy Step | 12 | 6s | 10 | 18 stud blink, tiny invincible window (0.12s). |
| Nova Sphere | 64 in a blast | 42s | 75 | Slow projectile, explodes for radius 14. Blockable. |

A clean opener without the ultimate (aura + beam + bolt + step) is about 70 damage and 60 energy. The ultimate is a finisher, not something you press with every other move.

**Counterplay.** Block the beam and the sphere. The bolt is the poke, so don't stand still and trade with it if you are melee. Stun during Power Aura. The step is short, so range still favors you if you keep walking.

## Brawler

Melee. Default slots: Heavy Punch, Grab Toss, Ground Slam, Shoulder Charge, ultimate Crater Drop. Iron Body is the swap if you want to live longer.

| Ability | Damage | Cooldown | Energy | Notes |
| --- | --- | --- | --- | --- |
| Heavy Punch | 22 | 3.5s | 8 | Super-armor for 0.35s. Range 8. |
| Grab Toss | 16 + 0.85s stun | 10s | 16 | Close. The stun is the setup. |
| Ground Slam | 20 | 8s | 18 | Radius 14, slow to 65% speed for 1.4s. |
| Shoulder Charge | 18 | 7s | 12 | 22 stud rush, super-armor for 0.3s. |
| Iron Body | 40% less damage, super-armor | 16s | 20 | 4 seconds. Slows still apply. Stuns and knockback do not. |
| Crater Drop | 58 | 40s | 70 | Radius 18, super-armor for 0.8s. |

Standing in their face and eating every button is about the same damage as a Ki Warrior who never misses, but the Brawler has to be close. Punch + charge is close to what in-combat regen can pay for. Slam, grab, and the ultimate are the extras.

**Counterplay.** Stay outside range 8. Slows work through super-armor. Stuns work in the gaps (the armor on a punch is a third of a second, not a permanent state). Trade with projectiles while they walk in. Block still cuts the punches.

## Speedster

Mobility. Default slots: Burst Dash, Blink Strike, Rapid Flurry, Afterimage, ultimate Tempo Barrage.

| Ability | Damage | Cooldown | Energy | Notes |
| --- | --- | --- | --- | --- |
| Burst Dash | 0 | 2.5s | 8 | 30 studs, invincible for 0.15s. |
| Blink Strike | 24 | 5s | 14 | 28 studs, hits along the path. |
| Rapid Flurry | 7 x 6 = 42 | 8s | 20 | You have to be in range 7. |
| Afterimage | 0 | 12s | 14 | Invincible for 0.5s. |
| Speed Trap | 14 | 9s | 16 | Radius 15, slow to 50% speed for 2s. |
| Tempo Barrage | 10 x 8 = 80 | 40s | 72 | Eight hits in front of you. A stun stops the rest. |

Blink + flurry is the damage (about 66 if both land) and costs 34 energy. The dash and Afterimage are how they don't die while that comes off cooldown. They should not beat a Brawler who is already hugging them, and they should not beat a Ki Warrior who never lets them arrive.

**Counterplay.** Hit between the dashes. The invincible windows are short on purpose. Area attacks still catch the landing. Block the flurry. Stun the ultimate and the later hits never come out.

## Elemental

Control. Default slots: Fire Bolt, Ice Shard, Lightning Spike, Flame Wave, ultimate Storm Cage.

| Ability | Damage | Cooldown | Energy | Notes |
| --- | --- | --- | --- | --- |
| Fire Bolt | 20 | 4.5s | 14 | Straight projectile. |
| Ice Shard | 12 | 6s | 14 | Slow to 55% speed for 2.2s. |
| Lightning Spike | 26 | 9s | 20 | 0.4s stun. Fast projectile. |
| Frost Burst | 16 | 11s | 22 | Radius 16, slow to 45% speed for 2.4s. |
| Flame Wave | 20 | 8s | 18 | A cone 22 studs long. |
| Storm Cage | 48 | 44s | 78 | Radius 18 and a 1.05s stun. |

On one target this is a bit less damage than Ki Warrior. On two or three people the areas pull ahead. The slows are the class: a slowed Brawler does not get to throw the grab.

**Counterplay.** Block Lightning Spike and Storm Cage (the stun still applies if the hit lands; block only cuts damage). Spread out so Frost Burst and Storm Cage hit one person. Afterimage or Log Swap through the cage. Super-armor ignores the stun but not the slow.

## Ninja

Tricks. Default slots: Shuriken Fan, Log Swap, Shadow Clone, Spiral Palm, ultimate Clone Rush.

| Ability | Damage | Cooldown | Energy | Notes |
| --- | --- | --- | --- | --- |
| Shuriken Fan | 9 x 3 = 27 | 4s | 12 | Spread. Dodging one star is normal. |
| Log Swap | 0 | 8s | 14 | Blink, leaves a log, invincible for 0.4s. |
| Shadow Clone | 8 per punch | 16s | 26 | Punches every 1.5s for up to 8s. **Any damaging hit destroys it.** |
| Spiral Palm | 28 | 6.5s | 16 | Close, strong knockback. |
| Wall Blink | 0 | 4.5s | 10 | 26 studs. Steps up if a wall is in the way. |
| Clone Rush | 16 x 5 = 80 | 42s | 70 | Five clones charge. **A hit destroys that clone before it deals damage.** |

If all three stars hit and the palm hits, that is real damage. They often will not. The clone is not a second health bar: it soaks **one** hit and then it is gone, and your own attacks do not pop your own clone. Count on 0 to 8 extra damage from it unless nobody looks at it.

**Counterplay.** Tap the clone. Any projectile, punch, or beam destroys it and that hit does not also hurt the ninja if the clone was in front (a beam stops on the clone). Area attacks still hit the ninja and pop the clone together. Do not chase a Log Swap in a straight line. Block the stars. The rush clones die the same way, one hit each, so a beam or a slam wastes several of them.

## Superhero

Burst, expensive. Default slots: Thermal Gaze, Flight, Power Punch, Dive Bomb, ultimate Horizon Beam.

| Ability | Damage | Cooldown | Energy | Notes |
| --- | --- | --- | --- | --- |
| Thermal Gaze | 12 x 5 = 60 | 7s | 60 up front | 1.25s channel. Needs line of sight. Block cuts each tick. A stun cancels the rest. The energy is spent even if you are stunned immediately. |
| Flight | 0 | 0.6s | 12 per second | Toggle. No blocking in the air. At 0 energy you fall and are stunned for 0.7s. |
| Power Punch | 26 | 4.5s | 12 | Range 9, heavy knockback. |
| Sonic Clap | 16 | 8s | 16 | Radius 18, the strongest knockback in the kit. |
| Dive Bomb | 36 in the air, 18 on the ground | 10s | 18 | "In the air" means Flying, or more than 12 studs above the ground. |
| Horizon Beam | 8 x 10 = 80 | 45s | 80 up front | 2.5s sweep. Same block and stun rules as Thermal Gaze. |

Thermal Gaze is the strongest basic button in the game **when it lands clean**. It also costs 60 of 100 energy, so the follow-up is one punch, not a full combo, and in-combat regen needs about 12 seconds to pay for another one. Flight spends the same bar: about 8 seconds airborne, and during that time you cannot gaze. Dive Bomb is the reward for being in the air (36 instead of 18).

**Counterplay.**

- **Lasers.** Block them. Each tick is reduced to 35%. A stun on the caster ends the channel and they already paid the full energy. A wall ends the beam; it does not bend.
- **Flight.** You cannot block while flying, and you are not invincible. Any damaging hit that is not stopped by super-armor (Superhero does not have super-armor) knocks you down and stuns you for 0.35 seconds. Projectiles, beams, and melee all count. A stun does the same. Running the bar to empty also drops you, with a longer 0.7 second stun.
- **Dive Bomb.** If they are on the ground it is only 18. Stun or knock them down before they dive.

## Swapping the feel

- Longer fights: raise `PlayerHealth` (try 150 or 200). Do not multiply every ability unless you want the same time-to-kill with bigger numbers.
- Make blocking stronger: lower `BlockDamageMultiplier` (0.2 means blocked hits deal 20%).
- Soften a flyer’s landing: set `FlightKnockdownStun` to 0. They still drop out of the sky. A higher number holds them on the ground longer. Raise `Abilities.Flight.energyPerSecond` to make flight run out sooner.
- Make clones tankier: they are hard-coded to die to any damaging hit in `CombatService.ApplyDamage`. That is the counterplay. Don't give them a big health pool if you want that to stay true.

Iron Body's 40% reduction stacks with a block: the hit is reduced, then the block takes 35% of what remains. That is strong on purpose and it lasts 4 seconds on a 16 second cooldown.

## Extra pool moves

Each class now has 8 normal moves and 2 ultimates. The starter loadout is unchanged, so the rotations above are still the baseline. The new moves are sidegrades: similar cost and damage to something already in the kit, so equipping them is a choice, not a power bump.

| Class | Added moves | Added ultimate |
| --- | --- | --- |
| Ki Warrior | Ki Burst 16, Charged Shot 26, Ki Barrier (30% reduction, 3s) | Dragon Wave, 10 x 8 ticks |
| Brawler | Uppercut 18 + stun, Lariat 20, War Cry slow | Quake Line 62 |
| Speedster | Spark Kick 18, Zip Upper 14 dash, Static Field 12 + short stun | Storm Run 70 dash |
| Elemental | Ember Burst 18, Hail Volley 6 x 4, Gale Push 10 + heavy knockback | Inferno Column 66 |
| Ninja | Smoke Veil (iframe + slow), Needle Toss 14, Rising Kick 20 | Thousand Stars 8 x 8 |
| Superhero | Heat Pulse 22 beam, Hero Slam 22, Shockwave Leap 16 | Solar Flare 70 |

Cooldowns and energy for these are in `Balance.Abilities` next to the originals. Lasers in the new pool (Dragon Wave, Heat Pulse) follow the same block and stun rules.

## Basic combo and shift dash

These are fillers. They are not class abilities.

| Action | Numbers |
| --- | --- |
| Click combo | 3 + 4 + 4 + 8 damage. Energy 3, 3, 3, 4. 0.34s between hits. Resets if you wait 0.95s. The 4th hit knocks back. |
| Shift dash | 14 studs, 10 energy, 2.8s cooldown, a very short invincible window (0.08s). No damage. |

Speedster Burst Dash is still 30 studs. The shift dash is the universal one.

Walk speed is 18 (was the default 16) so moving between hits feels less stuck. It does not change ability damage.

Aiming does not change damage either. Projectiles still use their old speed and range, so a shot can be sidestepped. Ground areas such as Ground Slam and Storm Cage can be placed up to 36 studs away. The blast radius is the same number as before.
