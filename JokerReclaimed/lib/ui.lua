local J = JRC

local function text(value, scale, colour)
    return {n = G.UIT.T, config = {text = value, scale = scale or 0.35,
        colour = colour or G.C.WHITE, shadow = true}}
end

local function row(nodes, config)
    return {n = G.UIT.R, config = config or {align = 'cm', padding = 0.04}, nodes = nodes}
end

local function column(nodes, config)
    return {n = G.UIT.C, config = config or {align = 'cm', padding = 0.07}, nodes = nodes}
end

local function button(label, callback, ref, colour, width, height, func)
    return UIBox_button{label = {label}, button = callback, ref_table = ref,
        colour = colour or G.C.GREEN, minw = width or 2.5, minh = height or 0.55,
        scale = 0.34, padding = 0.05, func = func,
        -- Native one_press permanently disables the existing UIElement.
        -- Navigation buttons must stay reusable after closing their overlay.
        one_press = callback == 'jrc_buy' or callback == 'jrc_confirm_tear'}
end

local function icon(size)
    local sprite = Sprite(0, 0, size, size, G.ASSET_ATLAS.jrc_scraps, {x = 0, y = 0})
    sprite.states.drag.can, sprite.states.hover.can, sprite.states.collide.can = false, false, false
    return {n = G.UIT.O, config = {object = sprite}}
end

local function header()
    J.sync()
    return row({icon(0.6), column({row({text(J.text('title'), 0.5, G.C.GOLD)}),
        row({text(J.text('balance', {J.display.scraps, G.GAME.dollars}), 0.33)})})})
end

local function preview(center, scale, options)
    local area = CardArea(0, 0, G.CARD_W * scale + 0.2, G.CARD_H * scale + 0.1,
        {card_limit = 1, card_w = G.CARD_W * scale, type = 'title', highlight_limit = 0, collection = true})
    area.jrc_preview = true
    -- One-card thumbnails need exact centering; native title areas add fan/bob offsets.
    local align_cards = area.align_cards
    area.align_cards = function(self)
        align_cards(self)
        for _, item in ipairs(self.cards) do
            item.T.x = self.T.x + (self.T.w - item.T.w) / 2
            item.T.y = self.T.y + (self.T.h - item.T.h) / 2
            item.T.r = 0
            -- Zero retains the native shader's mouse-position update without idle tilt.
            item.ambient_tilt = 0
        end
    end
    local card = Card(0, 0, G.CARD_W * scale, G.CARD_H * scale, G.P_CARDS.empty, center,
        {bypass_discovery_center = true, bypass_discovery_ui = true})
    card.jrc_preview_key = center.key
    card.states.drag.can = false
    card.sticker = nil
    if options then
        card:set_edition(options.edition ~= 'none' and {[options.edition] = true} or nil, true, true)
        card.ability.eternal, card.ability.perishable, card.ability.rental = nil, nil, nil
        if options.eternal then card:set_eternal(true) end
        if options.perishable then card:set_perishable(true) end
        if options.rental then card:set_rental(true) end
    end
    area:emplace(card)
    return {n = G.UIT.O, config = {object = area}}
end

local function catalogue_ui()
    local session = J.session
    local pool = J.catalogue(session.filter)
    local pages = math.max(1, math.ceil(#pool / J.balance.page_size))
    session.page = math.min(math.max(session.page, 1), pages)
    local contents = {header()}
    local filters = {J.text('all'), J.text('common'), J.text('uncommon'), J.text('rare'), J.text('legendary')}
    contents[#contents + 1] = row({create_option_cycle{
        options = filters, current_option = session.filter + 1, w = 3.2, h = 0.55, text_scale = 0.34,
        opt_callback = 'jrc_filter', colour = G.C.PALE_GREEN, no_pips = true,
    }})
    for r = 1, 2 do
        local cards = {}
        for c = 1, 4 do
            local center = pool[(session.page - 1) * J.balance.page_size + (r - 1) * 4 + c]
            if center then
                local price = J.quote(center, {edition = 'none'})
                local name = localize{type = 'name_text', set = 'Joker', key = center.key}
                cards[#cards + 1] = column({
                    row({preview(center, 0.64)}),
                    row({text(name, 0.27)}, {align = 'cm', maxw = 2.35}),
                    button(J.text('price', {price.scraps, price.dollars}), 'jrc_select', center,
                        G.C.PALE_GREEN, 2.35, 0.48),
                }, {align = 'cm', padding = 0.05, minw = 2.5, colour = G.C.BLACK, r = 0.1})
            else
                cards[#cards + 1] = column({}, {align = 'cm', minw = 2.5, minh = 2.45})
            end
        end
        contents[#contents + 1] = row(cards, {align = 'cm', padding = 0.06})
    end
    if #pool == 0 then contents[#contents + 1] = row({text(J.text('empty'), 0.35)}) end
    contents[#contents + 1] = row({
        column({button('<', 'jrc_page', {delta = -1, pages = pages}, G.C.GREY, 0.8)}),
        text(J.text('page', {session.page, pages, #pool}), 0.3),
        column({button('>', 'jrc_page', {delta = 1, pages = pages}, G.C.GREY, 0.8)}),
    })
    contents[#contents + 1] = row({text(J.notice or J.text('catalogue_hint'), 0.27, G.C.JOKER_GREY)})
    return create_UIBox_generic_options{contents = {column(contents)}, padding = 0.08,
        back_label = J.text('back_shop'), back_func = 'jrc_close'}
end

local function detail_ui()
    local center, options = J.session.center, J.session.options
    local price = J.quote(center, options)
    local allowed, reason = J.can_buy(center, options)
    local controls = {}
    controls[#controls + 1] = row({text(J.text('stickers'), 0.4, G.C.GOLD)})
    for _, key in ipairs({'rental', 'perishable', 'eternal'}) do
        local compat = center[key .. '_compat'] ~= false
        local active = options[key]
        local suffix = compat and ('  $' .. J.balance.sticker_dollars[key]) or ('  ' .. J.text('unavailable'))
        controls[#controls + 1] = button((active and '[X] ' or '[ ] ') .. J.text(key) .. suffix,
            compat and 'jrc_sticker' or 'nil', {key = key},
            compat and (active and G.C.PALE_GREEN or G.C.GREY) or G.C.UI.BACKGROUND_INACTIVE, 4.7, 0.52)
    end
    controls[#controls + 1] = row({text(J.text('sticker_hint'), 0.27, G.C.JOKER_GREY)}, {align = 'cm', maxw = 4.7})
    controls[#controls + 1] = row({text(J.text('editions'), 0.4, G.C.GOLD)})
    local editions, selected = {}, 1
    for i, key in ipairs({'none', 'foil', 'holo', 'polychrome', 'negative'}) do
        editions[i] = J.text(key) .. ' (+' .. J.balance.editions[key] .. ')'
        if options.edition == key then selected = i end
    end
    controls[#controls + 1] = row({create_option_cycle{
        options = editions, current_option = selected, w = 3.2, h = 0.55, text_scale = 0.34,
        opt_callback = 'jrc_edition', colour = G.C.PURPLE, no_pips = true,
    }})
    controls[#controls + 1] = row({text(J.text('edition_hint'), 0.28, G.C.JOKER_GREY)}, {align = 'cm', maxw = 4.7})
    controls[#controls + 1] = button(J.text('buy_price', {price.scraps, price.dollars}),
        'jrc_buy', center, G.C.GREEN, 4.7, 0.75, 'jrc_can_buy')
    controls[#controls + 1] = row({text(J.notice or (allowed and J.text('ready') or J.text(reason)),
        0.28, allowed and G.C.JOKER_GREY or G.C.ORANGE)}, {align = 'cm', maxw = 4.7})
    local name = localize{type = 'name_text', set = 'Joker', key = center.key}
    return create_UIBox_generic_options{contents = {column({header(), row({
        column({row({preview(center, 1.15, options)}),
            row({text(name, 0.4)}, {align = 'cm', maxw = 3.4}),
            row({text(J.text('preview_hint'), 0.27, G.C.JOKER_GREY)}, {align = 'cm', maxw = 3.5})},
            {align = 'cm', padding = 0.15, minw = 3.8}),
        column(controls),
    })})}, back_func = 'jrc_back_catalogue', back_label = J.text('back_catalogue'),
        back_id = 'jrc_back_catalogue'}
end

function J.refresh()
    if not J.session then return end
    -- Native Moveables remember whether they were created on pause.
    -- Set this before constructing cards, sprites, and option-cycle DynaText.
    G.SETTINGS.paused = true
    local definition = J.session.center and detail_ui() or catalogue_ui()
    local previous = G.NO_MOD_CURSOR_STACK
    if G.OVERLAY_MENU then G.NO_MOD_CURSOR_STACK = true end
    G.FUNCS.overlay_menu{definition = definition}
    G.NO_MOD_CURSOR_STACK = previous
end

G.FUNCS.jrc_open = function()
    if not J.in_shop() or G.OVERLAY_MENU then return end
    J.session = {page = 1, filter = 0, options = {edition = 'none'}}
    J.notice = J.wallet.error and J.text('save_error') or nil
    J.refresh()
end

G.FUNCS.jrc_close = function() G.FUNCS.exit_overlay_menu() end
G.FUNCS.jrc_back_catalogue = function()
    if not J.session then return end
    J.session.center, J.notice = nil, nil
    J.refresh()
end
G.FUNCS.jrc_select = function(e)
    if not J.session or not e.config.ref_table then return end
    J.session.center, J.session.options, J.notice = e.config.ref_table, {edition = 'none'}, nil
    J.refresh()
end
G.FUNCS.jrc_page = function(e)
    J.session.page = ((J.session.page - 1 + e.config.ref_table.delta) % e.config.ref_table.pages) + 1
    J.refresh()
end
G.FUNCS.jrc_filter = function(args)
    if not J.session then return end
    J.session.filter, J.session.page = args.to_key - 1, 1
    J.refresh()
end
G.FUNCS.jrc_edition = function(args)
    if not J.session then return end
    J.session.options.edition = ({'none', 'foil', 'holo', 'polychrome', 'negative'})[args.to_key]
    J.notice = nil
    J.refresh()
end
G.FUNCS.jrc_sticker = function(e)
    local key = e.config.ref_table.key
    local options = J.session.options
    options[key] = not options[key]
    if options[key] and key == 'eternal' then options.perishable = false end
    if options[key] and key == 'perishable' then options.eternal = false end
    J.notice = nil
    J.refresh()
end
G.FUNCS.jrc_can_buy = function(e)
    local allowed = J.session and J.can_buy(J.session.center, J.session.options)
    e.config.colour = allowed and G.C.GREEN or G.C.UI.BACKGROUND_INACTIVE
    e.config.button = allowed and 'jrc_buy' or nil
end
G.FUNCS.jrc_buy = function()
    if not J.session then return end
    if not J.buy(J.session.center, J.session.options) then J.refresh() end
end

G.FUNCS.jrc_can_tear = function(e)
    local allowed = J.can_tear(e.config.ref_table)
    e.config.colour = allowed and G.C.ORANGE or G.C.UI.BACKGROUND_INACTIVE
    e.config.button = allowed and 'jrc_ask_tear' or nil
end
G.FUNCS.jrc_ask_tear = function(e)
    local card = e.config.ref_table
    if not J.can_tear(card) then return end
    if not J.mod.config.confirm_tear then J.tear(card); return end
    J.pending_tear = card
    local amount = J.rules.tier(J.balance, card.config.center).scraps
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{definition = create_UIBox_generic_options{
        back_label = J.text('cancel'), contents = {column({
            row({icon(0.8), text(J.text('tear_title'), 0.5, G.C.GOLD)}),
            row({text(localize{type = 'name_text', set = 'Joker', key = card.config.center.key}, 0.4)}),
            row({text(J.text('tear_confirm', {amount}), 0.35)}),
            row({text(J.text('tear_warning'), 0.3, G.C.JOKER_GREY)}),
            button(J.text('tear'), 'jrc_confirm_tear', card, G.C.ORANGE, 4, 0.8),
        })},
    }}
end
G.FUNCS.jrc_confirm_tear = function(e)
    local card = e.config.ref_table
    G.FUNCS.exit_overlay_menu()
    -- Overlay exit locks one frame. Execute after that frame instead of bypassing safety.
    local requested = G.TIMERS.REAL
    G.E_MANAGER:add_event(Event{trigger = 'after', delay = 0.12, timer = 'REAL',
        blocking = false, blockable = false, func = function()
        if not card or card.removed or card.area ~= G.jokers then return true end
        if G.CONTROLLER.locked then return G.TIMERS.REAL - requested > 3 end
        J.tear(card)
        return true
    end})
end

local exit_overlay = G.FUNCS.exit_overlay_menu
G.FUNCS.exit_overlay_menu = function(...)
    J.session, J.pending_tear = nil, nil
    return exit_overlay(...)
end

local card_click = Card.click
function Card:click(...)
    if self.jrc_preview_key and J.session and not J.session.center then
        G.FUNCS.jrc_select{config = {ref_table = G.P_CENTERS[self.jrc_preview_key]}}
        return
    end
    return card_click(self, ...)
end

-- Append to the existing definition so other mods' actions are preserved.
local use_sell = G.UIDEF.use_and_sell_buttons
G.UIDEF.use_and_sell_buttons = function(card)
    local definition = use_sell(card)
    if card.area == G.jokers and card.ability.set == 'Joker' then
        local amount = J.rules.tier(J.balance, card.config.center).scraps
        local tear = row({column({
            {n = G.UIT.C, config = {ref_table = card, align = 'cr', padding = 0.1, r = 0.08,
                minw = 1.25, hover = true, shadow = true, colour = G.C.ORANGE,
                button = 'jrc_ask_tear', func = 'jrc_can_tear'}, nodes = {
                {n = G.UIT.B, config = {w = 0.1, h = 0.6}},
                column({row({text(J.text('tear'), 0.3)}, {align = 'cm', maxw = 1.15}),
                    row({text('+' .. amount, 0.45, G.C.GOLD)})}, {align = 'tm'}),
            }},
        }, {align = 'cr'})}, {align = 'cl'})
        if definition and definition.nodes and definition.nodes[1] and definition.nodes[1].nodes then
            table.insert(definition.nodes[1].nodes, tear)
        end
    end
    return definition
end

local function insert_shop_button(node)
    if not node or not node.nodes then return false end
    for _, child in ipairs(node.nodes) do
        if child.config and child.config.id == 'next_round_button' then
            child.config.minh = math.min(child.config.minh or 1.1, 1.1)
            for _, other in ipairs(node.nodes) do
                if other.config and other.config.button == 'reroll_shop' then other.config.minh = 1.15 end
            end
            node.nodes[#node.nodes + 1] = button(J.text('restore'), 'jrc_open', nil, G.C.PALE_GREEN, 2.8, 0.65)
            node.nodes[#node.nodes + 1] = row({
                text(J.text('scraps') .. ' ', 0.27, G.C.GOLD),
                {n = G.UIT.T, config = {ref_table = J.display, ref_value = 'scraps', scale = 0.3, colour = G.C.GOLD}},
            })
            return true
        end
        if insert_shop_button(child) then return true end
    end
    return false
end

local shop = G.UIDEF.shop
G.UIDEF.shop = function(...)
    J.sync()
    local definition = shop(...)
    if not insert_shop_button(definition) then
        -- F7 remains an accessible fallback if another mod replaces the shop structure.
        sendWarnMessage('Custom shop layout: use F7 to open Joker Reclaimed.', 'JokerReclaimed')
    end
    return definition
end
