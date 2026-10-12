-- Two independently validated JSON snapshots. Writes are read back before committing.
-- This file is separate from both the run save and the installed mod directory.
local Wallet = {}
Wallet.__index = Wallet

local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local function integer(n)
    return type(n) == 'number' and n == n and n >= 0 and n < 9007199254740991 and n % 1 == 0
end

function Wallet.new(fs, json, directory)
    return setmetatable({fs = fs, json = json, directory = directory}, Wallet)
end

function Wallet:decode(text)
    if type(text) ~= 'string' then return nil end
    local ok, data = pcall(self.json.decode, text)
    if not ok or type(data) ~= 'table' or data.version ~= 1
        or not integer(data.revision) or not integer(data.scraps)
        or not integer(data.next_run) or type(data.transactions) ~= 'table' then return nil end
    for _, tx in ipairs(data.transactions) do
        if type(tx) ~= 'table' or type(tx.id) ~= 'string' or type(tx.kind) ~= 'string'
            or not integer(tx.scraps) then return nil end
    end
    return data
end

function Wallet:load()
    self.fs.createDirectory(self.directory)
    local best, exists
    for _, suffix in ipairs({'a', 'b'}) do
        local path = self.directory .. '/wallet-' .. suffix .. '.json'
        if self.fs.getInfo(path) then exists = true end
        local data = self:decode(self.fs.read(path))
        if data and (not best or data.revision > best.revision) then best = data end
    end
    if not best and exists then
        self.error = 'Both wallet snapshots are unreadable. Restore a backup; no balance was reset.'
        return false, self.error
    end
    self.data = best or {version = 1, revision = 0, scraps = 0, next_run = 1, transactions = {}}
    self.error = nil
    return true
end

function Wallet:commit(next_data)
    next_data = copy(next_data)
    next_data.revision = self.data.revision + 1
    local suffix = next_data.revision % 2 == 1 and 'a' or 'b'
    local path = self.directory .. '/wallet-' .. suffix .. '.json'
    local ok, encoded = pcall(self.json.encode, next_data)
    if not ok then return false, 'encode' end
    local wrote = self.fs.write(path, encoded)
    if not wrote then return false, 'write' end
    local readback = self.fs.read(path)
    if readback ~= encoded or not self:decode(readback) then return false, 'verify' end
    self.data = next_data
    return true
end

function Wallet:find(id)
    for _, tx in ipairs(self.data.transactions) do
        if tx.id == id then return tx end
    end
end

function Wallet:transaction(tx, delta)
    if not self.data or self.error then return false, 'wallet' end
    if self:find(tx.id) then return false, 'duplicate' end
    if not integer(self.data.scraps + delta) then return false, 'funds' end
    local data = copy(self.data)
    data.scraps = data.scraps + delta
    data.transactions[#data.transactions + 1] = copy(tx)
    return self:commit(data)
end

function Wallet:allocate_run()
    local data = copy(self.data)
    local id = tostring(data.next_run)
    data.next_run = data.next_run + 1
    local ok = self:commit(data)
    return ok and id or nil
end

return Wallet
