local B = dofile('JokerReclaimed/balance.lua')
local R = dofile('JokerReclaimed/lib/rules.lua')
local Wallet = dofile('JokerReclaimed/lib/wallet.lua')
local json = dofile(os.getenv('APPDATA') .. '/Balatro/Mods/smods-main/libs/json/json.lua')
local assertions = 0
local function eq(actual, expected, message)
    assertions = assertions + 1
    assert(actual == expected, (message or '') .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end

for rarity, expected in ipairs({{1, 10}, {3, 30}, {7, 60}, {20, 100}}) do
    local center = {key = 'test', rarity = rarity, set = 'Joker', cost = 7, unlocked = true}
    eq(R.tier(B, center).scraps, expected[1], 'tear reward')
    for edition, extra in pairs(B.editions) do
        for _, selected in ipairs({{}, {rental = true}, {perishable = true}, {eternal = true},
                {rental = true, perishable = true}, {rental = true, eternal = true}}) do
            selected.edition = edition
            local price = assert(R.quote(B, center, selected, 6))
            eq(price.scraps, expected[2] + extra, 'sticker must never replace scrap cost')
            eq(price.dollars, selected.eternal and 2 or (selected.rental or selected.perishable) and 1
                or rarity == 4 and 10 or 6, 'dollar replacement')
        end
    end
end
eq(R.options_valid(B, {}, {eternal = true, perishable = true}), false)
eq(R.options_valid(B, {eternal_compat = false}, {eternal = true}), false)
eq(R.options_valid(B, {perishable_compat = false}, {perishable = true}), false)
eq(R.options_valid(B, {}, {edition = 'bogus'}), false)
eq(R.has_space(5, 5, 0, 'none'), false)
eq(R.has_space(5, 5, 0, 'negative'), true)
eq(R.has_space(6, 5, 0, 'negative'), false)
eq(R.has_space(4, 5, 1, 'none'), false)
eq(R.unlocked({set = 'Joker', key = 'a', unlocked = true}, {}), true)
eq(R.unlocked({set = 'Joker', key = 'a', unlocked = false}, {}), false)
eq(R.unlocked({set = 'Joker', key = 'a'}, {a = true}), false)
eq(R.tier(B, {rarity = 'mod_rare'}).price, 60)
B.custom_rarities.mod_rare = {price = 42, scraps = 8}
eq(R.tier(B, {rarity = 'mod_rare'}).price, 42)

local files, fail_write = {}, false
local fs = {
    createDirectory = function() return true end,
    getInfo = function(path) return files[path] and {} or nil end,
    read = function(path) return files[path] end,
    write = function(path, data)
        if fail_write then return false end
        files[path] = data
        return true
    end,
}
local w = Wallet.new(fs, json, 'test')
eq(w:load(), true)
eq(w.data.scraps, 0)
eq(w:allocate_run(), '1')
eq(w:transaction({id = 'tear:1:1', kind = 'tear', scraps = 20}, 20), true)
eq(w.data.scraps, 20)
eq(w:transaction({id = 'tear:1:1', kind = 'tear', scraps = 20}, 20), false, 'replay denied')
eq(w.data.scraps, 20)
eq(w:transaction({id = 'restore:3', kind = 'restore', scraps = 10}, -10), true)
eq(w.data.scraps, 10)
eq(w:transaction({id = 'restore:4', kind = 'restore', scraps = 60}, -60), false)
eq(w.data.scraps, 10)
fail_write = true
eq(w:transaction({id = 'tear:1:2', kind = 'tear', scraps = 7}, 7), false)
eq(w.data.scraps, 10, 'failed write keeps in-memory balance')
fail_write = false
local reloaded = Wallet.new(fs, json, 'test')
eq(reloaded:load(), true)
eq(reloaded.data.scraps, 10, 'restart persistence')
files['test/wallet-a.json'] = '{broken'
eq(reloaded:load(), true, 'recover other slot')
eq(reloaded.data.scraps, 20)
files['test/wallet-b.json'] = '{broken'
eq(reloaded:load(), false, 'fail closed on corrupt wallet')
eq(reloaded:transaction({id = 'tear:1:3', kind = 'tear', scraps = 20}, 20), false)
print('PASS: ' .. assertions .. ' economy and persistence assertions')
