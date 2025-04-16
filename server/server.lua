local Core = exports.vorp_core:GetCore()
local T = Translation.Langs[Config.Lang]

local function printCharacterSkills(character)
    if character and character.skills then
    else
    end
end

RegisterNetEvent("vlab_perks:requestAvatar")
AddEventHandler("vlab_perks:requestAvatar", function()
    local src = source
    local user = Core.getUser(src)
    if not user then 
        return 
    end
    local character = user.getUsedCharacter
    if not character then
        return
    end
    local firstname = character.firstname or character.FirstName or "Unknown"
    local lastname = character.lastname or character.LastName or "Unknown"
    local job = character.job or character.Job or "No Job"
    local charId = character.charIdentifier
    if not charId then
        return
    end
    exports.vlab_perks:GetPointsByCharId(charId, function(points)
        if not Config.DiscordAvatar then
            TriggerClientEvent("vlab_perks:sendAvatar", src, "img/logo.png", firstname, lastname, job, points)
            return
        end
        local discordId = nil
        for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
            if string.find(identifier, "discord:") then
                discordId = string.gsub(identifier, "discord:", "")
                break
            end
        end
        local avatarUrl = "img/placeholder.png"
        local headers = { 
            ["Authorization"] = "Bot " .. Config.DiscordToken, 
            ["User-Agent"] = "DiscordBot (https://discord.com, v0.1)" 
        }
        local function sendAvatar()
            TriggerClientEvent("vlab_perks:sendAvatar", src, avatarUrl, firstname, lastname, job, points)
        end
        if discordId then
            PerformHttpRequest("https://discord.com/api/guilds/" .. Config.guildId .. "/members/" .. discordId, function(statusCode, responseText)
                if statusCode == 200 then
                    local memberData = json.decode(responseText)
                    if memberData and memberData.avatar then
                        avatarUrl = "https://cdn.discordapp.com/avatars/" .. discordId .. "/" .. memberData.avatar .. ".png"
                    end
                end
                PerformHttpRequest("https://discord.com/api/users/" .. discordId, function(statusCode2, responseText2)
                    if statusCode2 == 200 then
                        local userData = json.decode(responseText2)
                        if userData and userData.avatar then
                            avatarUrl = "https://cdn.discordapp.com/avatars/" .. discordId .. "/" .. userData.avatar .. ".png"
                        end
                    end
                    sendAvatar()
                end, "GET", "", headers)
            end, "GET", "", headers)
        else
            sendAvatar()
        end
    end)
end)

local function printCharacterSkills(character)
    if character and character.skills then
    else
    end
end

local function mergeSkills(configSkills, dynamicSkills)
    local merged = {}
    for i, skillConfig in ipairs(configSkills) do
        local name = skillConfig.skillName
        if dynamicSkills and dynamicSkills[name] then
            merged[#merged+1] = {
                skillName = name,
                skillLabel = skillConfig.skillLabel,
                Level = tonumber(dynamicSkills[name].Level) or 1,
                Exp = tonumber(dynamicSkills[name].Exp) or 0
            }
        else
            merged[#merged+1] = {
                skillName = name,
                skillLabel = skillConfig.skillLabel,
                Level = 1,
                Exp = 0
            }
        end
    end
    return merged
end

function sendSkills(src, dynamicSkills)
    if Config.Skills then
        local merged = mergeSkills(Config.Skills, dynamicSkills)
        TriggerClientEvent("vlab_perks:sendSkills", src, merged)
    else
    end
end

RegisterNetEvent("vlab_perks:openInterface")
AddEventHandler("vlab_perks:openInterface", function()
    local src = source
    local user = Core.getUser(src)
    if not user then
        return
    end
    local character = user.getUsedCharacter
    if not character then
        return
    end
    printCharacterSkills(character)
    local steam = nil
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(identifier, "steam:") then
            steam = identifier
            break
        end
    end
    if not steam then
        return
    end
    local charId = character.charIdentifier
    local firstname = character.firstname or "Unknown"
    local lastname = character.lastname or "Unknown"
    exports.oxmysql:fetch("SELECT COUNT(*) as count FROM vlab_perks WHERE steam = @steam AND charId = @charId", 
        { ['@steam'] = steam, ['@charId'] = charId }, 
        function(result)
            local count = 0
            if result and result[1] and result[1].count then
                count = tonumber(result[1].count)
            end
            if count == 0 then
                exports.oxmysql:execute("INSERT INTO vlab_perks (steam, charId, firstname, lastname) VALUES (@steam, @charId, @firstname, @lastname)",
                    { ['@steam'] = steam, ['@charId'] = charId, ['@firstname'] = firstname, ['@lastname'] = lastname },
                    function(resultInsert)
                        if resultInsert and resultInsert.affectedRows and resultInsert.affectedRows > 0 then
                        else
                        end
                        TriggerClientEvent("vlab_perks:sendConfig", src, {
                            perks = Config.Perks,
                            skills = Config.Skills
                        })
                        exports.vlab_perks:GetAcquiredPerksByCharId(charId, function(acquired)
                            TriggerClientEvent("vlab_perks:sendAcquiredPerks", src, acquired)
                        end)
                        sendSkills(src, character.skills)
                    end
                )
            else
                TriggerClientEvent("vlab_perks:sendConfig", src, {
                    perks = Config.Perks,
                    skills = Config.Skills
                })
                exports.vlab_perks:GetAcquiredPerksByCharId(charId, function(acquired)
                    TriggerClientEvent("vlab_perks:sendAcquiredPerks", src, acquired)
                end)
                sendSkills(src, character.skills)
            end
        end
    )
end)

local function checkAndConvertExp(steam, charId)
    exports.oxmysql:fetch("SELECT exp, point FROM vlab_perks WHERE steam = @steam AND charId = @charId", {
        ['@steam'] = steam,
        ['@charId'] = charId
    }, function(result)
        if result and result[1] then
            local currentExp = tonumber(result[1].exp) or 0
            local currentPoints = tonumber(result[1].point) or 0
            local expThreshold = 100 -- EXP needed for conversion
            local pointsPerConversion = 1 -- Amount of points obtained per conversion

            if currentExp >= expThreshold then
                local timesExceeded = math.floor(currentExp / expThreshold)
                local newPoints = currentPoints + (pointsPerConversion * timesExceeded)
                local remainingExp = currentExp % expThreshold
                exports.oxmysql:execute("UPDATE vlab_perks SET exp = @exp, point = @point WHERE steam = @steam AND charId = @charId", {
                    ['@exp'] = remainingExp,
                    ['@point'] = newPoints,
                    ['@steam'] = steam,
                    ['@charId'] = charId
                }, function(updateResult)
                    if updateResult and updateResult.affectedRows > 0 then
                    else
                    end
                end)
            else
            end
        else
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.EXP.IncreaseTime)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local user = Core.getUser(tonumber(playerId))
            if user then
                local character = user.getUsedCharacter
                if character then
                    local steam = nil
                    local charId = character.charIdentifier
                    for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
                        if string.find(identifier, "steam:") then
                            steam = identifier
                            break
                        end
                    end
                    if steam and charId then
                        exports.oxmysql:execute("UPDATE vlab_perks SET exp = exp + " .. Config.EXP.IncrementPoints .. " WHERE steam = @steam AND charId = @charId",
                            { ['@steam'] = steam, ['@charId'] = charId },
                            function(result)
                                if result and result.affectedRows and result.affectedRows > 0 then
                                    checkAndConvertExp(steam, charId)
                                else
                                end
                            end
                        )
                    end
                end
            end
        end
    end
end)

local function AddPointsByCharId(charId, points)
    exports.oxmysql:execute("UPDATE vlab_perks SET point = point + @points WHERE charId = @charId", {
        ['@points'] = points,
        ['@charId'] = charId
    }, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
        else
        end
    end)
end

exports("AddPointsByCharId", AddPointsByCharId)

local function GetPointsByCharId(charId, cb)
    exports.oxmysql:fetch("SELECT point FROM vlab_perks WHERE charId = @charId", {
        ['@charId'] = charId
    }, function(result)
        local points = 0
        if result and result[1] and result[1].point then
            points = tonumber(result[1].point)
        end
        cb(points)
    end)
end

exports("GetPointsByCharId", GetPointsByCharId)

local function GetProgressByCharId(charId, cb)
    exports.oxmysql:fetch("SELECT exp FROM vlab_perks WHERE charId = @charId", {
        ['@charId'] = charId
    }, function(result)
        local progress = 0.00
        if result and result[1] and result[1].exp then
            local currentExp = tonumber(result[1].exp) or 0
            progress = math.min((currentExp / 100) * 100, 100)
        end
        cb(progress)
    end)
end

exports("GetProgressByCharId", GetProgressByCharId)

RegisterNetEvent("vlab_perks:sendConfig")
AddEventHandler("vlab_perks:sendConfig", function()
    local src = source
    TriggerClientEvent("vlab_perks:receiveConfig", src, {
        perks = Config.Perks,
        skills = Config.Skills
    })
end)

local function RemovePointsByCharId(charId, points)
    exports.oxmysql:execute("UPDATE vlab_perks SET point = point - @points WHERE charId = @charId AND point >= @points", {
        ['@points'] = points,
        ['@charId'] = charId
    }, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
        else
        end
    end)
end

exports("RemovePointsByCharId", RemovePointsByCharId)

RegisterNetEvent("vlab_perks:acquirePerk")
AddEventHandler("vlab_perks:acquirePerk", function(perkColumn, pointCost, moneyCost)
    local src = source
    pointCost = tonumber(pointCost) or 0
    moneyCost = tonumber(moneyCost) or 0

    if moneyCost == 0 then
        for _, perk in ipairs(Config.Perks) do
            if perk.funcs == perkColumn then
                moneyCost = tonumber(perk.money) or 0
                pointCost = tonumber(perk.point) or pointCost
                break
            end
        end
    end

    local user = Core.getUser(src)
    if not user then
        return
    end

    local character = user.getUsedCharacter
    if not character then
        return
    end

    local charId = character.charIdentifier
    if not charId then
        return
    end

    local currentMoney = tonumber(character.money) or 0

    exports.vlab_perks:HasAcquiredPerk(charId, perkColumn, function(hasPerk)
        if hasPerk then
            TriggerClientEvent("vlab_perks:acquirePerkResult", src, false, "Perk already acquired!")
            return
        else
            exports.vlab_perks:GetPointsByCharId(charId, function(points)
                if points < pointCost then
                    TriggerClientEvent("vlab_perks:acquirePerkResult", src, false, T.NoPoints)
                    TriggerClientEvent('vorp:TipBottom', src, "~e~"..T.NoPoints, 4000)
                elseif currentMoney < moneyCost then
                    TriggerClientEvent("vlab_perks:acquirePerkResult", src, false, T.NoMoney)
                    TriggerClientEvent('vorp:TipBottom', src, "~e~"..T.NoMoney, 4000)
                else
                    exports.vlab_perks:RemovePointsByCharId(charId, pointCost)
                    TriggerEvent("vorp:removeMoney", src, 0, moneyCost)
                    local query = "UPDATE vlab_perks SET " .. perkColumn .. " = 1 WHERE charId = @charId"
                    exports.oxmysql:execute(query, { ['@charId'] = charId }, function(result)
                        if result and result.affectedRows and result.affectedRows > 0 then
                            TriggerClientEvent("vlab_perks:acquirePerkResult", src, true, "Perk acquired!")
                            exports.vlab_perks:GetPointsByCharId(charId, function(newPoints)
                                TriggerClientEvent("vlab_perks:updatePoints", src, newPoints)
                            end)
                            exports.vlab_perks:GetAcquiredPerksByCharId(charId, function(acquired)
                                TriggerClientEvent("vlab_perks:sendAcquiredPerks", src, acquired)
                            end)
                        else
                            TriggerClientEvent("vlab_perks:acquirePerkResult", src, false, "Error acquiring perk!")
                        end
                    end)
                end
            end)
        end
    end)
end)

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
    a_moment_to_recuperate = true,
    quite_an_inspiration = true,
    sharpshooter = true,
    strange_medicine = true,
    the_unblinking_eye = true,
    gunslingers_choice = true,
    take_the_pain_away = true
}

local function HasAcquiredPerk(charId, perkColumn, cb)
    if not allowedPerkColumns[perkColumn] then
        cb(false)
        return
    end
    local query = "SELECT " .. perkColumn .. " as perkValue FROM vlab_perks WHERE charId = @charId"
    exports.oxmysql:fetch(query, { ['@charId'] = charId }, function(result)
        if result and result[1] then
            local value = result[1].perkValue
            local acquired = (value == true or tonumber(value) == 1)
            cb(acquired)
        else
            cb(false)
        end
    end)
end

exports("HasAcquiredPerk", HasAcquiredPerk)

local function AddExpByCharId(charId, expToAdd)
    exports.oxmysql:execute("UPDATE vlab_perks SET exp = exp + @exp WHERE charId = @charId", {
        ['@exp'] = expToAdd,
        ['@charId'] = charId
    }, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
        else
        end
    end)
end

exports("AddExpByCharId", AddExpByCharId)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(600000)
        local players = GetPlayers()
        for _, player in ipairs(players) do
            local source = tonumber(player)
            local user = Core.getUser(source)
            if not user then
            else
                local character = user.getUsedCharacter
                if not character then
                else
                    local charId = character.charIdentifier
                    if not charId then
                    else
                        exports.vlab_perks:HasAcquiredPerk(charId, "quite_an_inspiration", function(hasPerk)
                            if hasPerk then
                                local bonusExp = Config.EXP.IncrementPoints * 2
                                exports.vlab_perks:AddExpByCharId(charId, bonusExp)
                            else
                            end
                        end)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("vlab_perks:redeemReward")
AddEventHandler("vlab_perks:redeemReward", function(rewardName, RewardLabel, amount, skillKey, rewardLevel, rewardType)
    local src = source
    amount = tonumber(amount) or 1
    rewardLevel = tonumber(rewardLevel) or 0
    rewardType = tostring(rewardType or "item")
    local Core = exports.vorp_core:GetCore()
    local user = Core.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end
    local charId = character.charIdentifier
    local steam = nil
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(identifier, "steam:") then
            steam = identifier
            break
        end
    end
    if not steam then return end
    local redemptionStr = skillKey .. ":" .. tostring(rewardLevel)
    exports.oxmysql:fetch("SELECT redeem FROM vlab_perks WHERE steam = @steam AND charId = @charId", {
        ['@steam'] = steam,
        ['@charId'] = charId
    }, function(result)
        local current = result[1] and result[1].redeem or ""
        if string.find(current, redemptionStr) then
            TriggerClientEvent("vlab_perks:redeemRewardResult", src, {
                status = "error",
                message = "You have already redeemed this reward!"
            })
            return
        end
        local function handleSuccess()
            local newRedeem = (current == "") and redemptionStr or (current .. "," .. redemptionStr)
            exports.oxmysql:execute("UPDATE vlab_perks SET redeem = @newRedeem WHERE steam = @steam AND charId = @charId", {
                ['@newRedeem'] = newRedeem,
                ['@steam'] = steam,
                ['@charId'] = charId
            }, function()
                exports.vlab_perks:GetRedeemedRewardsByCharId(charId, function(redeemed)
                    TriggerClientEvent("vlab_perks:sendRedeemedRewards", src, redeemed)
                end)
            end)
        end
        if rewardType == "weapon" then
            exports.vorp_inventory:canCarryWeapons(src, 1, function(canCarry)
                if not canCarry then
                    TriggerClientEvent('vorp:TipBottom', src, T.WeaponInventoryFull, 4000)
                    return
                end
                local serial = "SKILL" .. os.time()
                local label = RewardLabel or rewardName
                local desc = "Ricompensa per la skill"
                local success = exports.vorp_inventory:createWeapon(src, rewardName, {
                    ammo = 0,
                    components = {},
                    comps = {},
                    serial = serial,
                    label = label,
                    description = desc
                })
                if not success then
                    return
                end
                TriggerClientEvent('vorp:TipBottom', src, T.YouHaveRedeemed..": ~o~" .. RewardLabel, 4000)
                handleSuccess()
            end, rewardName)
        else
            exports.vorp_inventory:canCarryItem(src, rewardName, amount, function(canCarry)
                if not canCarry then
                    TriggerClientEvent('vorp:TipBottom', src, T.ItemInventoryFull, 4000)
                    return
                end
                exports.vorp_inventory:addItem(src, rewardName, amount, {}, function(success)
                    if not success then
                        return
                    end
                    TriggerClientEvent('vorp:TipBottom', src, T.YouHaveRedeemed .. " " .. amount .. "x " .. " ~o~" .. RewardLabel, 4000)
                    handleSuccess()
                end, false)
            end)
        end
    end)
end)

local function GetRedeemedRewardsByCharId(charId, cb)
    exports.oxmysql:fetch("SELECT redeem FROM vlab_perks WHERE charId = @charId", {
        ['@charId'] = charId
    }, function(result)
        local redeemed = {}
        if result and result[1] and result[1].redeem then
            for reward in string.gmatch(result[1].redeem, "[^,]+") do
                table.insert(redeemed, reward)
            end
        end
        cb(redeemed)
    end)
end

exports("GetRedeemedRewardsByCharId", GetRedeemedRewardsByCharId)

RegisterNetEvent("vlab_perks:requestRedeemedRewards")
AddEventHandler("vlab_perks:requestRedeemedRewards", function()
    local src = source
    local Core = exports.vorp_core:GetCore()
    local user = Core.getUser(src)
    if not user then
        return
    end
    local character = user.getUsedCharacter
    if not character then
        return
    end
    local charId = character.charIdentifier
    GetRedeemedRewardsByCharId(charId, function(redeemed)
        TriggerClientEvent("vlab_perks:sendRedeemedRewards", src, redeemed)
    end)
end)