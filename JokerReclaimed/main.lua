local mod = SMODS.current_mod
JRC = {mod = mod, balance = assert(SMODS.load_file('balance.lua'))()}
local J = JRC
J.rules = assert(SMODS.load_file('lib/rules.lua'))()
local Wallet = assert(SMODS.load_file('lib/wallet.lua'))()
J.wallet = Wallet.new(love.filesystem, JSON or require('json'), J.balance.wallet_directory)
J.wallet:load()
J.display = {scraps = J.wallet.data and J.wallet.data.scraps or 0}
assert(SMODS.load_file('lib/effects.lua'))()

SMODS.Atlas{key = 'scraps', path = 'scraps.png', px = 32, py = 32}
SMODS.Atlas{key = 'modicon', path = 'modicon.png', px = 32, py = 32}

function J.text(key, vars)
    if vars then return localize{type = 'variable', key = 'jrc_' .. key, vars = vars} end
    return localize('jrc_' .. key)
end

function J.sync()
    J.display.scraps = J.wallet.data and J.wallet.data.scraps or 0
end

function J.update_slots()
    if G.jokers and G.jokers.handle_card_limit then G.jokers:handle_card_limit() end
end

function J.message(key, card)
    if card then
        card_eval_status_text(card, 'extra', nil, nil, nil, {message = J.text(key), colour = G.C.ORANGE})
    else
        J.notice = J.text(key)
    end
end

function J.save()
    if G.STAGE == G.STAGES.RUN and G.GAME and G.jokers then
        save_run()
        if G.FILE_HANDLER then G.FILE_HANDLER.force = true end
    end
end

function J.ensure_run()
    if not J.wallet.data or J.wallet.error or not G.GAME or not G.jokers then return false end
    if not G.GAME.jrc_run_id then
        G.GAME.jrc_run_id = J.wallet:allocate_run()
        if not G.GAME.jrc_run_id then return false end
        G.GAME.jrc_applied = {}
        J.save()
    end
    G.GAME.jrc_applied = G.GAME.jrc_applied or {}
    return true
end

function J.in_shop()
    return G.STAGE == G.STAGES.RUN and G.STATE == G.STATES.SHOP and G.shop and G.jokers
        and not J.busy and not G.GAME.jrc_recovery_blocked
end

function J.can_tear(card)
    if not card or not G.jokers or card.area ~= G.jokers or card.ability.set ~= 'Joker'
        or card.removed or card.getting_sliced or card.jrc_tearing or J.busy
        or G.GAME.jrc_recovery_blocked or not J.wallet.data or J.wallet.error then return false end
    if G.STAGE ~= G.STAGES.RUN or (G.play and #G.play.cards > 0)
        or G.CONTROLLER.locked or (G.GAME.STOP_USE or 0) > 0 then return false end
    if SMODS.is_eternal(card, {destroy_cards = true, jrc_tear = true}) then return false end
    return true
end

function J.tear(card)
    if not J.can_tear(card) or not J.ensure_run() then return false end
    local id = 'tear:' .. G.GAME.jrc_run_id .. ':' .. tostring(card.sort_id)
    if J.wallet:find(id) then J.message('already_torn', card); return false end
    local flags = SMODS.calculate_context({joker_type_destroyed = true, card = card, jrc_tear = true})
    if flags and flags.no_destroy then J.message('protected', card); return false end
    local amount = J.rules.tier(J.balance, card.config.center).scraps
    local tx = {id = id, kind = 'tear', run = G.GAME.jrc_run_id, card_id = card.sort_id, scraps = amount}
    if not J.wallet:transaction(tx, amount) then J.message('save_error', card); return false end
    J.sync()
    J.busy, card.jrc_tearing = true, true
    G.GAME.jrc_applied[id] = true
    if card.highlighted then G.jokers:remove_from_highlighted(card) end
    -- Remove the card from the saved area immediately; leave its sprite for the dissolve.
    card:remove_from_deck()
    G.jokers:remove_card(card)
    J.update_slots()
    J.play_tear(card, amount)
    J.save()
    G.E_MANAGER:add_event(Event{trigger = 'after', delay = 0.85, timer = 'REAL', blocking = false, func = function()
        J.busy = false
        return true
    end})
    return true
end

function J.catalogue(filter)
    local result = {}
    for _, center in pairs(G.P_CENTERS) do
        if J.rules.unlocked(center, G.GAME.banned_keys)
            and (not filter or filter == 0 or center.rarity == filter) then
            result[#result + 1] = center
        end
    end
    table.sort(result, function(a, b)
        if (a.order or 0) ~= (b.order or 0) then return (a.order or 0) < (b.order or 0) end
        return a.key < b.key
    end)
    return result
end

function J.quote(center, options)
    -- Probe vanilla pricing without edition/stickers (discounts and inflation included).
    local probe = setmetatable({base_cost = center.cost or 0, ability = {set = 'Joker'},
        config = {center = center}, facing = 'front'}, {__index = Card})
    Card.set_cost(probe)
    return J.rules.quote(J.balance, center, options, probe.cost)
end

function J.can_buy(center, options)
    if not J.in_shop() then return false, 'shop_only' end
    if not J.rules.unlocked(center, G.GAME.banned_keys) then return false, 'locked' end
    local price, why = J.quote(center, options)
    if not price then return false, why end
    if not J.wallet.data or J.wallet.error then return false, 'save_error' end
    if J.wallet.data.scraps < price.scraps then return false, 'need_scraps' end
    if G.GAME.dollars - (G.GAME.bankrupt_at or 0) < price.dollars then return false, 'need_money' end
    J.update_slots()
    local config = center.config or {}
    local extra_capacity = config.card_limit or 0
    if options.edition == 'negative' then
        extra_capacity = extra_capacity + ((G.P_CENTERS.e_negative.config or {}).card_limit or 1)
    end
    if #G.jokers.cards + (G.GAME.joker_buffer or 0) + 1 + (config.extra_slots_used or 0)
        > G.jokers.config.card_limit + extra_capacity then return false, 'no_space' end
    return true, price
end

function J.make_card(center, options)
    local card = SMODS.create_card{set = 'Joker', key = center.key, area = G.jokers,
        no_edition = true, skip_materialize = true, allow_duplicates = true}
    -- create_card may apply stake stickers; restoration is explicitly selected.
    card.ability.eternal, card.ability.perishable, card.ability.rental = nil, nil, nil
    card.ability.perish_tally = nil
    card:set_edition(options.edition ~= 'none' and { [options.edition] = true } or nil, true, true)
    if options.eternal then card:set_eternal(true) end
    if options.perishable then card:set_perishable(true) end
    if options.rental then card:set_rental(true) end
    card:set_cost()
    return card
end

function J.buy(center, options)
    local allowed, price = J.can_buy(center, options)
    if not allowed then J.message(price); return false end
    if not J.ensure_run() then J.message('save_error'); return false end
    J.busy = true
    local ok, card = pcall(J.make_card, center, options)
    if not ok then
        J.busy = false
        sendWarnMessage(tostring(card), 'JokerReclaimed')
        J.message('create_error')
        return false
    end
    if #G.jokers.cards + (G.GAME.joker_buffer or 0) + 1 + (card.ability.extra_slots_used or 0)
        > G.jokers.config.card_limit + (card.ability.card_limit or (options.edition == 'negative' and 1 or 0)) then
        card:remove()
        J.busy = false
        J.message('no_space')
        return false
    end
    local id = 'restore:' .. tostring(J.wallet.data.revision + 1)
    card.ability.jrc_restore_id = id
    -- Keep exact generated ability state for recovery from an interrupted run save.
    local tx = {id = id, kind = 'restore', run = G.GAME.jrc_run_id,
        scraps = price.scraps, dollars = price.dollars, center = center.key, card_data = STR_PACK(card:save())}
    if not J.wallet:transaction(tx, -price.scraps) then
        card:remove()
        J.busy = false
        J.message('save_error')
        return false
    end
    J.sync()
    ease_dollars(-price.dollars, true)
    card:add_to_deck()
    G.jokers:emplace(card)
    J.update_slots()
    G.GAME.jrc_applied[id] = true
    G.GAME.jrc_restored = (G.GAME.jrc_restored or 0) + 1
    if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
    card:start_materialize({G.C.GOLD, G.C.GREEN})
    play_sound('coin1')
    J.busy = false
    -- A purchase context, never selling_self/selling_card.
    SMODS.calculate_context({buying_card = true, card = card, jrc_restore = true})
    J.save()
    return true, card
end

function J.reconcile()
    if not J.ensure_run() then return end
    local changed = false
    for _, tx in ipairs(J.wallet.data.transactions) do
        if tx.run == G.GAME.jrc_run_id and not G.GAME.jrc_applied[tx.id] then
            if tx.kind == 'tear' then
                for i = #G.jokers.cards, 1, -1 do
                    if G.jokers.cards[i].sort_id == tx.card_id then G.jokers.cards[i]:remove() end
                end
            elseif tx.kind == 'restore' then
                if not G.P_CENTERS[tx.center] then
                    -- Keep the transaction pending until its supplying mod returns.
                    G.GAME.jrc_recovery_blocked = true
                    J.message('missing_mod')
                    return
                end
                local found
                for _, card in ipairs(G.jokers.cards) do
                    if card.ability.jrc_restore_id == tx.id then found = true end
                end
                if not found then
                    local card = Card(G.jokers.T.x, G.jokers.T.y, G.CARD_W, G.CARD_H,
                        G.P_CARDS.empty, G.P_CENTERS[tx.center])
                    card:load(tx.card_data and STR_UNPACK(tx.card_data) or tx.card)
                    card.added_to_deck = false
                    card:add_to_deck()
                    G.jokers:emplace(card)
                    ease_dollars(-tx.dollars, true)
                end
            elseif tx.kind == 'cheat' and tx.dollars then
                ease_dollars(tx.dollars, true)
            end
            G.GAME.jrc_applied[tx.id], changed = true, true
        end
    end
    G.GAME.jrc_recovery_blocked = nil
    J.update_slots()
    if changed then J.save() end
end

local start_run = Game.start_run
function Game:start_run(...)
    local result = start_run(self, ...)
    J.busy, J.session, J.notice = false, nil, nil
    G.E_MANAGER:add_event(Event{trigger = 'after', delay = 0.1, func = function()
        J.reconcile()
        return true
    end})
    return result
end

function J.cheat()
    if not mod.config.enable_cheats or G.STAGE ~= G.STAGES.RUN or J.busy
        or not J.ensure_run() then return end
    local amount = J.balance.cheats
    local tx = {id = 'cheat:' .. tostring(J.wallet.data.revision + 1), kind = 'cheat',
        run = G.GAME.jrc_run_id, scraps = amount.scraps, dollars = amount.dollars}
    if not J.wallet:transaction(tx, amount.scraps) then J.message('save_error'); return end
    ease_dollars(amount.dollars, true)
    G.GAME.jrc_applied[tx.id] = true
    G.GAME.jrc_cheated = true
    J.sync()
    J.save()
    play_sound('coin1')
    if J.session and G.OVERLAY_MENU then J.refresh() end
end

SMODS.Keybind{key = 'test_funds', key_pressed = J.balance.cheats.key,
    held_keys = {'lctrl', 'lshift'}, action = J.cheat}
SMODS.Keybind{key = 'open_restore', key_pressed = J.balance.cheats.shop_key,
    action = function() if J.in_shop() and not G.OVERLAY_MENU then G.FUNCS.jrc_open() end end}

assert(SMODS.load_file('lib/ui.lua'))()

mod.config_tab = function()
    return {n = G.UIT.ROOT, config = {align = 'cm', padding = 0.2, colour = G.C.BLACK, r = 0.1}, nodes = {
        create_toggle{label = J.text('confirm_setting'), ref_table = mod.config, ref_value = 'confirm_tear'},
        create_toggle{label = J.text('cheat_setting'), ref_table = mod.config, ref_value = 'enable_cheats'},
        {n = G.UIT.R, config = {align = 'cm'}, nodes = {
            {n = G.UIT.T, config = {text = J.text('cheat_hint'), scale = 0.3, colour = G.C.GOLD}}
        }},
    }}
end
