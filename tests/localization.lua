local root = 'JokerReclaimed/localization/'
local baseline = dofile(root .. 'en-us.lua')
local languages = {'en-us', 'ko', 'ja', 'zh_CN', 'zh_TW', 'de', 'fr', 'es_ES', 'es_419', 'pt_BR', 'it', 'id', 'ru', 'nl', 'pl'}
local count = 0
for _, language in ipairs(languages) do
    local locale = dofile(root .. language .. '.lua')
    for _, section in ipairs({'dictionary', 'v_dictionary'}) do
        for key, value in pairs(baseline.misc[section]) do
            local translated = locale.misc[section][key]
            assert(type(translated) == 'string' and translated ~= '' and translated ~= 'ERROR', language .. ': ' .. key)
            local function slots(text)
                local found = {}
                for slot in text:gmatch('#(%d+)#') do found[#found + 1] = slot end
                table.sort(found)
                return table.concat(found, ',')
            end
            assert(slots(value) == slots(translated), language .. ': placeholder mismatch: ' .. key)
            count = count + 1
        end
        for key in pairs(locale.misc[section]) do assert(baseline.misc[section][key], language .. ': unexpected key ' .. key) end
    end
end
print('PASS: ' .. #languages .. ' locales, ' .. count .. ' translated strings and placeholder checks')
