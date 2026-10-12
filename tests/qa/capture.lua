-- Documentation photography only, explicitly requested by the user.
-- Fixtures live in the isolated QA identity. This file is never distributed as a mod.
assert(love.filesystem.getIdentity() == 'Balatro-JRC-QA')
local languages = {'ko', 'en-us', 'ja', 'zh_CN', 'zh_TW', 'de', 'fr', 'es_ES',
    'es_419', 'pt_BR', 'it', 'id', 'ru', 'nl', 'pl'}
local report = {purpose = 'documentation screenshots', files = {}, languages = {},
    identity = love.filesystem.getIdentity(), width = 1600, height = 900}
local elapsed, wait_until, stage, index = 0, 2, 0, 1
local owned
love.filesystem.createDirectory('screenshots')
local function log(message)
    report.status = message
    love.filesystem.write('capture-report.json', JSON.encode(report))
    print('[JRC-CAPTURE] ' .. message)
end
local function capture(name)
    local path = 'screenshots/' .. languages[index] .. '-' .. name .. '.png'
    love.graphics.captureScreenshot(path)
    report.files[#report.files + 1] = path
    log('Captured ' .. languages[index] .. ': ' .. name)
end
local function find_button(node, callback)
    if not node then return end
    if node.UIRoot then node = node.UIRoot end
    if node.config and node.config.button == callback then return node end
    for _, child in pairs(node.children or {}) do
        local found = find_button(child, callback)
        if found then return found end
    end
end
local function click(node, callback)
    assert(find_button(node, callback), 'Missing capture target: ' .. callback):click()
end
local function next_stage(value, delay)
    stage, wait_until = value, elapsed + (delay or 1)
end
local original_update = Game.update
function Game:update(dt)
    original_update(self, dt)
    if report.finished then return end
    elapsed = elapsed + dt
    if elapsed < wait_until then return end
    local ok, err = xpcall(function()
        if stage == 0 then
            love.window.setMode(1600, 900, {fullscreen = false, resizable = false, vsync = 1})
            love.resize(1600, 900)
            G.SETTINGS.tutorial_complete = true
            G.SETTINGS.SOUND.volume = 0
            G.SETTINGS.GRAPHICS.crt = 0
            G.SETTINGS.GRAPHICS.bloom = 1
            love.mouse.setPosition(1580, 880)
            next_stage(1, 1)
        elseif stage == 1 then
            if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
            local language = languages[index]
            G.SETTINGS.language, G.SETTINGS.real_language = language, language
            G:set_language()
            SMODS.load_mod_localization(SMODS.path, '_')
            SMODS.load_mod_localization(JRC.mod.path, JRC.mod.id)
            init_localization()
            -- Rebuild the run so the HUD and shop use the same language as the overlay.
            G.FUNCS.start_run(nil, {stake = 1, seed = 'JRCGUIDE'})
            log('Preparing ' .. language)
            next_stage(2, 3)
        elseif stage == 2 then
            G.E_MANAGER:clear_queue()
            if G.blind_select then G.blind_select:remove(); G.blind_select = nil end
            if G.blind_prompt_box then G.blind_prompt_box:remove(); G.blind_prompt_box = nil end
            G.STATE, G.STATE_COMPLETE = G.STATES.SHOP, false
            next_stage(3, 4)
        elseif stage == 3 then
            if G.CONTROLLER.locked or not G.shop then wait_until = elapsed + 0.5; return end
            local delta = 250 - JRC.wallet.data.scraps
            assert(JRC.wallet:transaction({id = 'capture-fixture-' .. index,
                kind = 'qa_fixture', scraps = math.abs(delta)}, delta))
            ease_dollars(45 - G.GAME.dollars, true)
            JRC.sync()
            owned = JRC.make_card(G.P_CENTERS.j_joker, {edition = 'none'})
            owned:add_to_deck()
            G.jokers:emplace(owned)
            JRC.update_slots()
            G.jokers:add_to_highlighted(owned)
            next_stage(4, 1.5)
        elseif stage == 4 then
            capture('shop')
            next_stage(5, 0.2)
        elseif stage == 5 then
            click(owned.children.use_button, 'jrc_ask_tear')
            next_stage(6, 1)
        elseif stage == 6 then
            capture('tear')
            next_stage(7, 0.2)
        elseif stage == 7 then
            click(G.OVERLAY_MENU, 'jrc_confirm_tear')
            next_stage(8, 0.28)
        elseif stage == 8 then
            capture('effect')
            next_stage(9, 1.5)
        elseif stage == 9 then
            click(G.shop, 'jrc_open')
            next_stage(10, 1.5)
        elseif stage == 10 then
            assert(G.OVERLAY_MENU and JRC.session, 'Catalogue did not open')
            capture('intro')
            next_stage(11, 0.2)
        elseif stage == 11 then
            G.FUNCS.jrc_select{config = {ref_table = G.P_CENTERS.j_joker}}
            G.FUNCS.jrc_sticker{config = {ref_table = {key = 'rental'}}}
            G.FUNCS.jrc_edition{to_key = 4}
            next_stage(12, 1.5)
        elseif stage == 12 then
            capture('options')
            report.languages[#report.languages + 1] = languages[index]
            next_stage(13, 0.5)
        elseif stage == 13 then
            index = index + 1
            if index > #languages then
                report.finished, report.success = true, true
                log('All 15 languages captured')
                love.event.quit()
            else
                next_stage(1, 0.5)
            end
        end
    end, debug.traceback)
    if not ok then
        report.finished, report.success, report.error = true, false, err
        log('Capture failed: ' .. tostring(err))
        love.event.quit()
    end
end
