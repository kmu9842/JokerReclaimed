-- Runs only under .local/qa-mods and an isolated LOVE save identity.
assert(love.filesystem.getIdentity() == 'Balatro-JRC-QA', 'QA must never run in the real profile')
if os.getenv('JRC_QA_SCENARIO') == 'reopen' then
    return assert(SMODS.load_file('reopen.lua'))()
end
local report = {assertions = 0, steps = {}, errors = {}, identity = love.filesystem.getIdentity()}
local elapsed, stage, wait_until = 0, 0, 2
local torn_card, starting_balance, before_purchase, recovery_save, confirm_card, confirm_cash, confirm_scraps
local languages = {'ko', 'en-us', 'de', 'fr', 'es_ES', 'es_419', 'pt_BR', 'it', 'id', 'ru', 'nl', 'pl', 'ja', 'zh_CN', 'zh_TW'}
local language_index = 1
local function log(message)
    report.steps[#report.steps + 1] = message
    love.filesystem.write('qa-report.json', JSON.encode(report))
    print('[JRC-QA] ' .. message)
end
local function check(condition, message)
    report.assertions = report.assertions + 1
    assert(condition, message)
end
local function screenshot(name)
    love.graphics.captureScreenshot('qa-' .. name .. '.png')
end
local function ready()
    return not G.CONTROLLER.locked and (G.GAME.STOP_USE or 0) <= 0 and not JRC.busy
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
            G.SETTINGS.WINDOW = G.SETTINGS.WINDOW or {}
            G.FUNCS.start_run(nil, {stake = 1, seed = 'JRCTEST1'})
            log('Started isolated seeded run with installed Steamodded + DVPreview + QuickRestart')
            stage, wait_until = 1, elapsed + 3
        elseif stage == 1 then
            check(JRC ~= nil, 'mod loaded')
            check(G.ASSET_ATLAS.jrc_scraps ~= nil, 'Sunburst atlas registered')
            check(JRC.text('title') ~= 'ERROR', 'Korean mod localization loaded')
            G.E_MANAGER:clear_queue()
            if G.blind_select then G.blind_select:remove(); G.blind_select = nil end
            if G.blind_prompt_box then G.blind_prompt_box:remove(); G.blind_prompt_box = nil end
            G.STATE, G.STATE_COMPLETE = G.STATES.SHOP, false
            stage, wait_until = 2, elapsed + 4
        elseif stage == 2 then
            if not ready() then wait_until = elapsed + 0.5; return end
            check(G.shop ~= nil, 'vanilla shop created')
            local joker = G.P_CENTERS.j_joker
            local allowed, reason = JRC.can_buy(joker, {edition = 'none'})
            check(not allowed and reason == 'need_scraps', 'empty wallet rejects purchase')
            starting_balance = JRC.wallet.data.scraps
            -- Isolated QA fixture only; this file is never shipped with the mod.
            local fixture = {id = 'qa-funds', kind = 'qa_fixture', scraps = 1000}
            check(JRC.wallet:transaction(fixture, 1000), 'fixture funds saved')
            ease_dollars(100, true)
            JRC.sync()
            check(JRC.wallet.data.scraps == starting_balance + 1000, 'fixture scraps')
            check(G.GAME.dollars >= 100, 'fixture dollars')
            G.P_CENTERS.j_caino.unlocked, G.P_CENTERS.j_caino.discovered = true, true
            local locked = G.P_CENTERS.j_blueprint
            locked.unlocked = false
            local seen_locked, seen_legendary = false, false
            for _, c in ipairs(JRC.catalogue(0)) do
                if c.key == locked.key then seen_locked = true end
                if c.key == 'j_caino' then seen_legendary = true end
            end
            check(not seen_locked and seen_legendary, 'catalogue follows unlock flags')
            local base = JRC.quote(joker, {edition = 'none'})
            local cash = G.GAME.dollars
            local bought, card = JRC.buy(joker, {edition = 'none'})
            check(bought and card.area == G.jokers, 'restore adds real Joker')
            check(G.GAME.dollars == cash - base.dollars, 'base cash charged once')
            check(JRC.wallet.data.scraps == starting_balance + 1000 - 10, 'base scraps charged')
            torn_card = card
            log('Base purchase and unlock filter passed using isolated fixture funds')
            stage, wait_until = 3, elapsed + 2
        elseif stage == 3 then
            if not ready() then wait_until = elapsed + 0.5; return end
            recovery_save = STR_UNPACK(get_compressed(G.SETTINGS.profile .. '/save.jkr'))
            check(recovery_save and recovery_save.GAME.jrc_run_id == G.GAME.jrc_run_id, 'saved run identity exists before spending')
            local cash, scraps = G.GAME.dollars, JRC.wallet.data.scraps
            check(JRC.tear(torn_card), 'tear succeeds')
            check(G.GAME.dollars == cash, 'tearing grants no sale money')
            check(JRC.wallet.data.scraps == scraps + 1, 'common tear reward')
            check(not JRC.tear(torn_card), 'repeat tear denied')
            check(#G.jokers.cards == 0, 'torn card removed from area synchronously')
            log('Tear animation, no sale income, and duplicate rejection passed')
            stage, wait_until = 4, elapsed + 2
        elseif stage == 4 then
            if not ready() then wait_until = elapsed + 0.5; return end
            local money, scraps = G.GAME.dollars, JRC.wallet.data.scraps
            local bought, card = JRC.buy(G.P_CENTERS.j_caino, {edition = 'negative', rental = true, eternal = true})
            check(bought, 'legendary negative rental eternal restore')
            check(G.GAME.dollars == money - 2, 'eternal replaces dollars with 2')
            check(JRC.wallet.data.scraps == scraps - 150, 'legendary plus negative remains 150 scraps')
            check(card.ability.rental and card.ability.eternal and card.edition.negative, 'real sticker and edition flags')
            check(G.jokers.config.card_limit == 6, 'negative increases capacity')
            check(not JRC.can_tear(card), 'eternal cannot be torn')
            local before = JRC.wallet.data.scraps
            JRC.reconcile()
            check(JRC.wallet.data.scraps == before and #G.jokers.cards == 1, 'reconcile already applied is idempotent')
            log('Legendary pricing, combined stickers, negative slot and eternal protection passed')
            stage, wait_until = 5, elapsed + 2
        elseif stage == 5 then
            if not ready() then wait_until = elapsed + 0.5; return end
            G.FUNCS.jrc_open()
            check(G.OVERLAY_MENU and JRC.session, 'catalogue overlay opens')
            log('Catalogue UI rendered')
            stage, wait_until = 6, elapsed + 2
        elseif stage == 6 then
            for _, area in ipairs(G.I.CARDAREA) do
                if area.jrc_preview then
                    local card = area.cards[1]
                    check(math.abs(card.T.x + card.T.w / 2 - area.T.x - area.T.w / 2) < 0.00001,
                        'preview horizontally centered')
                    check(math.abs(card.T.y + card.T.h / 2 - area.T.y - area.T.h / 2) < 0.00001,
                        'preview vertically centered')
                    check(card.T.r == 0, 'preview has no idle rotation')
                end
            end
            screenshot('catalogue')
            stage, wait_until = 61, elapsed + 0.2
        elseif stage == 61 then
            G.FUNCS.jrc_select{config = {ref_table = G.P_CENTERS.j_joker}}
            G.FUNCS.jrc_sticker{config = {ref_table = {key = 'rental'}}}
            G.FUNCS.jrc_sticker{config = {ref_table = {key = 'perishable'}}}
            G.FUNCS.jrc_edition{to_key = 4}
            local price = JRC.quote(JRC.session.center, JRC.session.options)
            check(price.dollars == 1 and price.scraps == 30, 'rental perishable polychrome exact price')
            log('Selection, sticker toggles, edition cycle and final price UI rendered')
            stage, wait_until = 7, elapsed + 2
        elseif stage == 7 then
            screenshot('options')
            stage, wait_until = 71, elapsed + 0.2
        elseif stage == 71 then
            G.FUNCS.jrc_buy()
            check(not G.OVERLAY_MENU, 'purchase returns to shop')
            check(#G.jokers.cards == 2, 'second purchase added')
            stage, wait_until = 8, elapsed + 2
        elseif stage == 8 then
            screenshot('shop')
            stage, wait_until = 81, elapsed + 0.2
        elseif stage == 81 then
            confirm_card = G.jokers.cards[2]
            confirm_cash, confirm_scraps = G.GAME.dollars, JRC.wallet.data.scraps
            G.jokers:add_to_highlighted(confirm_card)
            stage, wait_until = 82, elapsed + 1
        elseif stage == 82 then
            screenshot('tear-button')
            stage, wait_until = 83, elapsed + 0.2
        elseif stage == 83 then
            G.FUNCS.jrc_ask_tear{config = {ref_table = confirm_card}}
            check(G.OVERLAY_MENU and JRC.pending_tear == confirm_card, 'tear confirmation opens')
            stage, wait_until = 84, elapsed + 1
        elseif stage == 84 then
            screenshot('tear-confirm')
            stage, wait_until = 85, elapsed + 0.2
        elseif stage == 85 then
            G.FUNCS.jrc_confirm_tear{config = {ref_table = confirm_card}}
            G.E_MANAGER:add_event(Event{trigger = 'after', delay = 0.36, timer = 'REAL',
                blocking = false, blockable = false, func = function()
                    screenshot('tear-fx')
                    return true
                end})
            stage, wait_until = 86, elapsed + 2
        elseif stage == 86 then
            check(#G.jokers.cards == 1, 'confirmation removes precisely one card')
            check(G.GAME.dollars == confirm_cash and JRC.wallet.data.scraps == confirm_scraps + 1,
                'confirmation preserves dollars and rewards once')
            before_purchase = JRC.wallet.data.scraps
            log('Tear button and confirmation callback passed')
            -- Replay a real earlier save while leaving the durable wallet at its latest state.
            G.FUNCS.start_run(nil, {savetext = recovery_save})
            stage, wait_until = 87, elapsed + 4
        elseif stage == 87 then
            check(JRC.wallet.data.scraps == before_purchase, 'recovery does not spend or award scraps twice')
            check(#G.jokers.cards == 1 and G.jokers.cards[1].config.center.key == 'j_caino',
                'recovery replays purchases and tears in order')
            check(G.GAME.dollars == confirm_cash, 'recovery charges pending purchases exactly once')
            JRC.reconcile()
            check(#G.jokers.cards == 1 and G.GAME.dollars == confirm_cash, 'repeated recovery is idempotent')
            log('Interrupted-save recovery passed using an earlier real run save')
            -- Reload wallet from disk and then start another run: no test mocks.
            local scraps = JRC.wallet.data.scraps
            check(JRC.wallet:load(), 'wallet reload')
            check(JRC.wallet.data.scraps == scraps, 'disk wallet matches')
            before_purchase = scraps
            G.FUNCS.start_run(nil, {stake = 1, seed = 'JRCTEST2'})
            stage, wait_until = 9, elapsed + 3
        elseif stage == 9 then
            check(JRC.wallet.data.scraps == before_purchase, 'wallet survives new run')
            check(#G.jokers.cards == 0, 'new run has no previous Jokers')
            log('Disk persistence and cross-run balance passed')
            G.E_MANAGER:clear_queue()
            if G.blind_select then G.blind_select:remove(); G.blind_select = nil end
            if G.blind_prompt_box then G.blind_prompt_box:remove(); G.blind_prompt_box = nil end
            G.STATE, G.STATE_COMPLETE = G.STATES.SHOP, false
            stage, wait_until = 10, elapsed + 3
        elseif stage == 10 then
            if not ready() then wait_until = elapsed + 0.5; return end
            local language = languages[language_index]
            G.SETTINGS.language, G.SETTINGS.real_language = language, language
            G:set_language()
            SMODS.load_mod_localization(SMODS.path, '_')
            SMODS.load_mod_localization(JRC.mod.path, JRC.mod.id)
            init_localization()
            check(JRC.text('title') ~= 'ERROR', language .. ' dictionary loaded')
            check(not JRC.text('balance', {123, 45}):find('#'), language .. ' variables substituted')
            local locale = assert(loadstring(NFS.read(JRC.mod.path .. 'localization/' .. language .. '.lua')))()
            for _, entries in pairs(locale.misc) do
                for key, value in pairs(entries) do
                    check(G.LANG.font.FONT:hasGlyphs(value), language .. ' font supports ' .. key)
                end
            end
            G.FUNCS.jrc_open()
            stage, wait_until = 11, elapsed + 1.2
        elseif stage == 11 then
            local language = languages[language_index]
            for _, area in ipairs(G.I.CARDAREA) do
                if area.jrc_preview then
                    local card = area.cards[1]
                    check(math.abs(card.VT.x + card.VT.w/2 - area.VT.x - area.VT.w/2) < 0.01,
                        language .. ' rendered card horizontally centered')
                    check(math.abs(card.VT.y + card.VT.h/2 - area.VT.y - area.VT.h/2) < 0.01,
                        language .. ' rendered card vertically centered')
                    check(card.tilt_var.mx > 0 and card.tilt_var.my > 0,
                        language .. ' card shader has initialized center')
                    check(card.hover_tilt == 0, language .. ' perspective cannot displace preview')
                end
            end
            screenshot('locale-' .. language .. '-catalogue')
            stage, wait_until = 12, elapsed + 0.2
        elseif stage == 12 then
            G.FUNCS.jrc_select{config = {ref_table = G.P_CENTERS.j_joker}}
            G.FUNCS.jrc_sticker{config = {ref_table = {key = 'rental'}}}
            G.FUNCS.jrc_edition{to_key = 5}
            stage, wait_until = 13, elapsed + 1.2
        elseif stage == 13 then
            for _, area in ipairs(G.I.CARDAREA) do
                if area.jrc_preview then
                    local card = area.cards[1]
                    check(math.abs(card.VT.x + card.VT.w/2 - area.VT.x - area.VT.w/2) < 0.01
                        and math.abs(card.VT.y + card.VT.h/2 - area.VT.y - area.VT.h/2) < 0.01
                        and card.hover_tilt == 0, languages[language_index] .. ' detail preview centered')
                end
            end
            screenshot('locale-' .. languages[language_index] .. '-options')
            stage, wait_until = 14, elapsed + 0.2
        elseif stage == 14 then
            G.FUNCS.jrc_close()
            log('Language UI and rendered card centers passed: ' .. languages[language_index])
            language_index = language_index + 1
            stage, wait_until = language_index <= #languages and 10 or 15, elapsed + 0.3
        elseif stage == 15 then
            report.finished, report.success = true, true
            log('PASS')
            love.event.quit()
        end
    end, debug.traceback)
    if not ok then
        report.finished, report.success = true, false
        report.errors[#report.errors + 1] = err
        log('FAIL: ' .. tostring(err))
        screenshot('failure')
        love.event.quit()
    end
end
