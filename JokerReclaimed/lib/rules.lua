-- Pure economy rules: no dependency on the game, also used by the tests.
local Rules = {}

function Rules.tier(balance, center)
    local rarity = center.rarity
    local aliases = {Common = 1, Uncommon = 2, Rare = 3, Legendary = 4}
    return balance.custom_rarities[rarity] or balance.rarities[aliases[rarity] or rarity]
        or balance.rarities[balance.fallback_rarity]
end

function Rules.unlocked(center, banned)
    return center and center.set == 'Joker' and center.unlocked ~= false
        and not center.omit and not center.no_collection
        and not (banned and banned[center.key])
end

function Rules.options_valid(balance, center, options)
    options = options or {}
    if balance.editions[options.edition or 'none'] == nil then return false, 'edition' end
    if options.eternal and options.perishable then return false, 'incompatible' end
    for _, key in ipairs({'eternal', 'perishable', 'rental'}) do
        if options[key] and center[key .. '_compat'] == false then return false, 'incompatible' end
    end
    return true
end

function Rules.quote(balance, center, options, normal_cost)
    options = options or {}
    local valid, why = Rules.options_valid(balance, center, options)
    if not valid then return nil, why end
    local tier = Rules.tier(balance, center)
    local dollars = tier.dollars or normal_cost or center.cost or 0
    local override
    for key, amount in pairs(balance.sticker_dollars) do
        if options[key] then override = math.max(override or 0, amount) end
    end
    return {
        scraps = tier.price + balance.editions[options.edition or 'none'],
        dollars = override or dollars,
    }
end

function Rules.has_space(count, limit, buffer, edition)
    return count + (buffer or 0) < limit + (edition == 'negative' and 1 or 0)
end

return Rules
