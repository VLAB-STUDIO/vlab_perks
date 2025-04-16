# How does it work?

`vlab_perks` is an advanced skill control system for **VORP CORE**, it uses vorp **API** to monitor the skill level. (*It is not a script to increase the experience, but only a control with an interface*).

`vlab_perks` also has an integrated skill card system, inspired by **RDO** and adapted for **RedM**; this system is separate from the **VORP** skills system.

Skill cards can be purchased by each player by spending money and points; (*points will be obtained by playing.*)
with an integrated playtime system, the script controls online players by adding exp to the database based on the CharID "*Works for multicharacter*" and through an event, it will convert the **EXP** into points. (*all configurable via* `config.lua`)

Each acquired skill card, has an export, by default, `vlab_perks`, has 8 skill cards:

```
- slippery_bastard
- a_moment_to_recuperate
- quite_an_inspiration
- sharpshooter
- strange_medicine
- the_unblinking_eye
- gunslingers_choice
- take_the_pain_away
```

The skill card: "`quite_an_inspiration`" is already present inside the script and when a player has it, the process to gain points will be speeded up.

> *This script is not a "`plug and play`" but you need to have programming knowledge to adapt it according to your needs.*

# Synchronization with VORP

The `vlab_perks` level display interface needs to be synchronized with **VORP CORE**.

go to vorp core and look for this path: "`vorp_core/config/skills.lua`"

Make sure that the skills you are going to use on `vlab_perks` are present on `vorp_core`:

> - Weapons
> - Mining
> - Naturalist
> - Fishing
> - Doctor
> - Hunting

You can disable their display by commenting the skill you do not want to display from `vlab_perks`.

Make sure the skills on `vorp_core` have 10 default levels like in this case:

```
Weapons = {
 Levels = {
 {
 NextLevel = 100,
 Label = "Beginner",
 },
 {
 NextLevel = 250,
 Label = "Novice",
 },
 {
 NextLevel = 500,
 Label = "Apprentice",
 },
 {
 NextLevel = 850,
 Label = "Journeyman",
 },
 {
 NextLevel = 1500,
 Label = "Expert",
 },
 {
 NextLevel = 2500,
 Label = "Expert II",
 },
 {
 NextLevel = 5000,
 Label = "Expert III",
 },
 {
 NextLevel = 10000,
 Label = "Expert IV",
},
{
NextLevel = 20000,
Label = "Expert V",
},
{
NextLevel = 50000,
Label = "Expert VI",
}
},
},
```

**Set the experience needed to reach the next level and the skill label as you see fit.**

# How to add new skills

You can add new skills, make sure to add them in both config files and add your skill image in the path: `vlab_perks\html\img`

Make sure in `vlab_perks` config:

```
Config.Skills = {
{
skillName = "Weapons",
skillLabel = "Gunslinger",
{
liv = 1,
label = "Test 1",
rewardType = "item",
rewardName = "coal",
RewardLabel = "Coal",
amount = "1",
},
...
```

The **skillName** is entered and has the same name inside **Config.Skills** in "`vorp_core/config/skills.lua`"

**Add rewards for each level reached:**

```
Config.Skills = {
{
skillName = "Weapons", -- The name of the skill that should match on vorp_core
skillLabel = "Gunslinger", -- Skill name translation in vlab_perks interface
{
liv = 1, -- Skill level
label = "Test 1", -- Skill level name in vlab_perks interface (may be different from vorp_core "your choice"
rewardType = "item", -- Reward type, choose between "item" or "weapon"
rewardName = "coal", -- Reward name, make sure it is in database if "item"
RewardLabel = "Coal", -- Reward translation in vlab_perks interface
amount = "1", -- Reward amount obtained.
},
...
```

*To create new resources that are compatible with the vorp API, follow the documentation: *https://docs.vorp-core.com/api-reference/core

# How to add new perks cards

**If you want to add a new skill card, make sure you know what you're doing first!**

Follow these steps:

- Add the image of the skill card in the path: `vlab_perks\html\img`
You can find the skill cards here: https://github.com/femga/rdr3_discoveries/tree/master/useful_info_from_rpfs/textures/ui_textures_mp____part1

- Add the new card in the **config.lua** `Config.Perks`

```
{
icon = "image", -- name of the image .png
label = "label", -- display name of the new card
desc = "description", -- description of the new card
funcs = "new_perk", -- name of the card that we are going to insert into the database and in the exports
point = 110, -- points needed to acquire the new card
money = 850 -- money needed to acquire the new card
},
```

- We add the new skill in the database, adding this query in the database:

```
`ALTER TABLE `vlab_perks`
ADD COLUMN `new_perk` TINYINT(1) NOT NULL DEFAULT 0 AFTER `take_the_pain_away`;
```

"**new_perk**" will be the name of the new skill card, which must match the **funcs** in **config.lua**.

- Search in the path `server/server.lua` for this function: "**GetAcquiredPerksByCharId**" copy this:

```
local function GetAcquiredPerksByCharId(charId, cb)
 exports.oxmysql:fetch(
 "SELECT slippery_bastard, a_moment_to_recuperate, quite_an_inspiration, sharpshooter, strange_medicine, the_unblinking_eye, gunslingers_choice, take_the_pain_away FROM vlab_perks WHERE charId = @charId",
 { ['@charId'] = charId },
 function(result)
 local acquiredPerks = {}
 if result and result[1] then
 local row = result[1]
 for perkName, value in pairs(row) do
 if value == true or tonumber(value) == 1 then
 table.insert(acquiredPerks, perkName)
 end
 end
 end
 cb(acquiredPerks)
 end
 )
end

exports("GetAcquiredPerksByCharId", GetAcquiredPerksByCharId)

local allowedPerkColumns = {
 slippery_bastard = true,
 a_moment_to_recover = true,
 quite_an_inspiration = true,
 sharpshooter = true,
 strange_medicine = true,
 the_unblinking_eye = true,
 gunslingers_choice = true,
 take_the_pain_away = true
}
```

Add the "**new_perk**":

```
local function GetAcquiredPerksByCharId(charId, cb)
 exports.oxmysql:fetch(
 "SELECT slippery_bastard, a_moment_to_recoverate, quite_an_inspiration, sharpshooter, strange_medicine, the_unblinking_eye, gunslingers_choice, take_the_pain_away, new_perk FROM vlab_perks WHERE charId = @charId",
 { ['@charId'] = charId },
 function(result)
 local acquiredPerks = {}
 if result and result[1] then
 local row = result[1]
 for perkName, value in pairs(row) do
 if value == true or tonumber(value) == 1 then
 table.insert(acquiredPerks, perkName)
 end
 end
 end
 cb(acquiredPerks)
 end
 )
end

exports("GetAcquiredPerksByCharId", GetAcquiredPerksByCharId)

local allowedPerkColumns = {
 slippery_bastard = true,
 a_moment_to_recover = true,
 quite_an_inspiration = true,
 sharpshooter = true,
 strange_medicine = true,
 the_unblinking_eye = true,
 gunslingers_choice = true,
 take_the_pain_away = true,
 new_perk = true
}
```

**It is important to know the export to check if a player has the acquired perk.**

- Export to check if the charID has acquired a perk specification

```exports("HasAcquiredPerk", HasAcquiredPerk)```

- Example

```
exports.vlab_perks:HasAcquiredPerk(charId, "new_perk", function(hasPerk)
 if hasPerk then
 print("The charId " .. charId .. " has acquired the perk 'new_perk'.")
 else
 print("The charId " .. charId .. " has NOT acquired the 'new_perk' perk.")
 end
end)
```

**If you want to add a new skill card, make sure you know what you're doing first!**

Follow these steps:

-  Add the image of the skill card in the path: `vlab_perks\html\img`
You can find the skill cards here: https://github.com/femga/rdr3_discoveries/tree/master/useful_info_from_rpfs/textures/ui_textures_mp____part1

-  Add the new card in the **config.lua** `Config.Perks`

```
{
icon = "image", -- name of the image .png
label = "label", -- display name of the new card
desc = "description", -- description of the new card
funcs = "new_perk", -- name of the card that we are going to insert into the database and in the exports
point = 110, -- points needed to acquire the new card
money = 850 -- money needed to acquire the new card
},
```

- We add the new skill in the database, adding this query in the database:

```
`ALTER TABLE `vlab_perks`
ADD COLUMN `new_perk` TINYINT(1) NOT NULL DEFAULT 0 AFTER `take_the_pain_away`;
```

"**new_perk**" will be the name of the new skill card, which must match the **funcs** in **config.lua**.

-  Search in the path `server/server.lua` for this function: "**GetAcquiredPerksByCharId**" copy this:

```
local function GetAcquiredPerksByCharId(charId, cb)
 exports.oxmysql:fetch(
 "SELECT slippery_bastard, a_moment_to_recuperate, quite_an_inspiration, sharpshooter, strange_medicine, the_unblinking_eye, gunslingers_choice, take_the_pain_away FROM vlab_perks WHERE charId = @charId",
 { ['@charId'] = charId },
 function(result)
 local acquiredPerks = {}
 if result and result[1] then
 local row = result[1]
 for perkName, value in pairs(row) do
 if value == true or tonumber(value) == 1 then
 table.insert(acquiredPerks, perkName)
 end
 end
 end
 cb(acquiredPerks)
 end
 )
end

exports("GetAcquiredPerksByCharId", GetAcquiredPerksByCharId)

local allowedPerkColumns = {
 slippery_bastard = true,
 a_moment_to_recover = true,
 quite_an_inspiration = true,
 sharpshooter = true,
 strange_medicine = true,
 the_unblinking_eye = true,
 gunslingers_choice = true,
 take_the_pain_away = true
}
```

Add the "**new_perk**":

```
local function GetAcquiredPerksByCharId(charId, cb)
 exports.oxmysql:fetch(
 "SELECT slippery_bastard, a_moment_to_recoverate, quite_an_inspiration, sharpshooter, strange_medicine, the_unblinking_eye, gunslingers_choice, take_the_pain_away, new_perk FROM vlab_perks WHERE charId = @charId",
 { ['@charId'] = charId },
 function(result)
 local acquiredPerks = {}
 if result and result[1] then
 local row = result[1]
 for perkName, value in pairs(row) do
 if value == true or tonumber(value) == 1 then
 table.insert(acquiredPerks, perkName)
 end
 end
 end
 cb(acquiredPerks)
 end
 )
end

exports("GetAcquiredPerksByCharId", GetAcquiredPerksByCharId)

local allowedPerkColumns = {
 slippery_bastard = true,
 a_moment_to_recover = true,
 quite_an_inspiration = true,
 sharpshooter = true,
 strange_medicine = true,
 the_unblinking_eye = true,
 gunslingers_choice = true,
 take_the_pain_away = true,
 new_perk = true
}
```

**It is important to know the export to check if a player has the acquired perk.**

- Export to check if the charID has acquired a perk specification

```exports("HasAcquiredPerk", HasAcquiredPerk)```

- Example

```
exports.vlab_perks:HasAcquiredPerk(charId, "new_perk", function(hasPerk)
 if hasPerk then
 print("The charId " .. charId .. " has acquired the perk 'new_perk'.")
 else
 print("The charId " .. charId .. " has NOT acquired the 'new_perk' perk.")
 end
end)
```

# Exports

- Export to add points to charID

```exports("AddPointsByCharId", AddPointsByCharId)```

- Example

```exports.vlab_perks:AddPointsByCharId(charId, pointsToAdd)```

- Export to retrieve how many points the player has

```exports("GetPointsByCharId", GetPointsByCharId)```

- Example

```exports.vlab_perks:GetPointsByCharId(charId, function(points)```

- Export to retrieve the percentage of progress to add a point

```exports("GetProgressByCharId", GetProgressByCharId)```

- Example

```exports.vlab_perks:GetProgressByCharId(charId, function(progress)```

- Export to remove points to charID

```exports("RemovePointsByCharId", RemovePointsByCharId)```

- Example

```exports.vlab_perks:RemovePointsByCharId(charId, pointsToRemove)```

- Export to recover all the perks acquired by the charID

```exports("GetAcquiredPerksByCharId", GetAcquiredPerksByCharId)```

- Example

```
exports.vlab_perks:GetAcquiredPerksByCharId(charId, function(acquired)
 print("Perks gained for charId " .. charId .. ":")
 for _, perk in ipairs(acquired) do
 print(perk)
 end
end)
```

- Export to check if the charID has acquired a perk specification

```exports("HasAcquiredPerk", HasAcquiredPerk)```

- Example

```
exports.vlab_perks:HasAcquiredPerk(charId, "sharpshooter", function(hasPerk)
 if hasPerk then
 print("The charId " .. charId .. " has acquired the perk 'sharpshooter'.")
 else
 print("The charId " .. charId .. " has NOT acquired the 'sharpshooter' perk.")
 end
end)
```

- Perks available:

```
- slippery_bastard
- slippery_bastard
- a_moment_to_recover
- quite_an_inspiration
- sharpshooter
- strange_medicine
- the_unblinking_eye
- gunslingers_choice
- take_the_pain_away
```

- Export to add EXP to charID

```exports("AddExpByCharId", AddExpByCharId)```

- Example

```exports.vlab_perks:AddExpByCharId(charId, bonusExp)```
