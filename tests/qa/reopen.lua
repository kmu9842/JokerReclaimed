-- Exercise native UIElement clicks: direct callbacks do not cover one_press behavior.
local report = {scenario = 'reopen', assertions = 0, steps = {}, errors = {}}
local elapsed, wait_until, stage, cycles = 0, 2, 0, 0
local shop_button, baseline_cards, baseline_scraps, baseline_dollars
local function log(message)
    report.steps[#report.steps + 1] = message
    love.filesystem.write('qa-reopen-report.json', JSON.encode(report))
    print('[JRC-QA] ' .. message)
end
local function check(condition, message)
    report.assertions = report.assertions + 1
    assert(condition, message)
end
local function find_button(node, callback)
    if node.UIRoot then node = node.UIRoot end
    if node.config and node.config.button == callback then return node end
    for _, child in pairs(node.children or {}) do
        local found = find_button(child, callback)
        if found then return found end
    end
end
local function click(root, callback)
    local node = find_button(root, callback)
    check(node ~= nil, 'button exists: ' .. callback)
    node:click()
    return node
end
local original_update = Game.update
function Game:update(dt)
    original_update(self, dt)
    if report.finished then return end
    elapsed = elapsed + dt
    if elapsed < wait_until then return end
    local ok, err = xpcall(function()
        if stage == 0 then
            G.SETTINGS.tutorial_complete = true
            G.FUNCS.start_run(nil, {stake = 1, seed = 'JRCREOPEN'})
            stage, wait_until = 1, elapsed + 3
        elseif stage == 1 then
            G.E_MANAGER:clear_queue()
            if G.blind_select then G.blind_select:remove(); G.blind_select = nil end
            if G.blind_prompt_box then G.blind_prompt_box:remove(); G.blind_prompt_box = nil end
            G.STATE, G.STATE_COMPLETE = G.STATES.SHOP, false
            stage, wait_until = 2, elapsed + 4
        elseif stage == 2 then
            check(G.shop ~= nil, 'native shop exists')
            baseline_cards, baseline_scraps, baseline_dollars = #G.jokers.cards, JRC.wallet.data.scraps, G.GAME.dollars
            shop_button = click(G.shop, 'jrc_open')
            check(G.OVERLAY_MENU and JRC.session, 'first actual shop-button click opens catalogue')
            log('Opened with actual UIElement click')
            stage, wait_until = 3, elapsed + 0.7
        elseif stage == 3 then
            click(G.OVERLAY_MENU, 'jrc_close')
            check(not G.OVERLAY_MENU and not JRC.session and not G.SETTINGS.paused, 'back button closes catalogue')
            stage, wait_until = 4, elapsed + 0.5
        elseif stage == 4 then
            shop_button:click()
            check(G.OVERLAY_MENU and JRC.session, 'same shop button reopens catalogue after closing')
            check(not shop_button.disable_button, 'persistent shop button remains clickable')
            cycles = cycles + 1
            log('Reopened via same shop button: ' .. cycles)
            stage, wait_until = 5, elapsed + 0.5
        elseif stage == 5 then
            if cycles % 2 == 0 then
                G.CONTROLLER:key_press('escape')
            else
                click(G.OVERLAY_MENU, 'jrc_close')
            end
            stage, wait_until = 55, elapsed + 0.4
        elseif stage == 55 then
            G.CONTROLLER:key_release('escape')
            check(not G.OVERLAY_MENU and not JRC.session, 'close returns to shop on cycle ' .. cycles)
            stage, wait_until = cycles < 10 and 4 or 6, elapsed + 0.5
        elseif stage == 6 then
            check(#G.jokers.cards == baseline_cards and JRC.wallet.data.scraps == baseline_scraps
                and G.GAME.dollars == baseline_dollars, 'repeated open and close changes no cards or funds')
            report.finished, report.success = true, true
            log('PASS')
            love.event.quit()
        end
    end, debug.traceback)
    if not ok then
        report.finished, report.success = true, false
        report.errors[#report.errors + 1] = err
        log('FAIL: ' .. tostring(err))
        love.event.quit()
    end
end
