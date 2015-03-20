local Class = require 'lib/class'
local Util = require 'lib/util'

bit32 = bit32 or bit

Zentropy = Zentropy or {
    db = {
        Project = {},
        Components = Class:new{
            SECTION_MASKS = {
                Util.oct('000001'),
                Util.oct('000002'),
                Util.oct('000004'),
                Util.oct('000010'),
                Util.oct('000020'),
                Util.oct('000040'),
                Util.oct('000100'),
                Util.oct('000200'),
                Util.oct('000400'),
            }
        },
    },
}

Zentropy.db.Project.__index = Zentropy.db.Project

function Zentropy.init()
    Zentropy.components = Zentropy.db.Components:new():parse()
end

function Zentropy.db.Project:parse()
    local entries = {}
    local filename = 'project_db.dat'
    local f = sol.main.load_file(filename)
    if not f then
        error("error: loading file: " .. filename)
    end

    local env = setmetatable({}, {__index=function(t, key)
        return function(properties)
            entries[key] = entries[key] or {}
            table.insert(entries[key], properties)
        end
    end})

    setfenv(f, env)()
    return entries
end

function Zentropy.db.Components:new(o)
    o = o or {}
    o.obstacles = o.obstacles or {}
    o.treasures = o.treasures or {}
    o.doors = o.doors or {}
    o.enemies = o.enemies or {}
    o.fillers = o.fillers or {}
    return Class.new(self, o)
end

function Zentropy.db.Components:obstacle(id, iterator)
    local item = iterator()
    local dir = iterator()
    local mask = iterator()
    local sequence = iterator()
    self.obstacles[item] = self.obstacles[item] or {}
    self.obstacles[item][dir] = self.obstacles[item][dir] or {}
    self.obstacles[item][dir][sequence] = {
        id=id,
        mask=mask,
    }
end

function Zentropy.db.Components:treasure(id, iterator)
    local open = iterator()
    local mask = iterator()
    local sequence = iterator()
    if mask ~= 'any' then
        mask = Util.oct(mask)
    end
    self.treasures[open] = self.treasures[open] or {}
    self.treasures[open][sequence] = {
        id=id,
        mask=mask,
    }
    local mask_string
    if mask == 'any' then
        mask_string = mask
    else
        mask_string = Util.fromoct(mask)
    end
    print(string.format('added treasure %s %d %s', open, sequence, mask_string))
end

function Zentropy.db.Components:door(id, iterator)
    local open = iterator()
    local dir = iterator()
    local mask = iterator()
    local sequence = iterator()
    self.doors[open] = self.doors[open] or {}
    self.doors[open][dir] = self.doors[open][dir] or {}
    self.doors[open][dir][sequence] = {
        id=id,
        mask=mask,
    }
end

function Zentropy.db.Components:enemy(id, iterator)
    local mask = iterator()
    local sequence = iterator()
    if mask ~= 'any' then
        mask = Util.oct(mask)
    end
    self.enemies[sequence] = {
        id=id,
        mask=mask,
    }
end

function Zentropy.db.Components:filler(id, iterator)
    local mask = iterator()
    local sequence = iterator()
    if mask ~= 'any' then
        mask = Util.oct(mask)
    end
    self.fillers[sequence] = {
        id=id,
        mask=mask,
    }
end

function Zentropy.db.Components:parse(maps)
    maps = maps or Zentropy.db.Project:parse().map

    for k, v in pairs(maps) do
        if string.sub(v.id, 0, 11) == 'components/' then
            local parts = string.gmatch(string.sub(v.id, 12), '[^_]+')
            local part = parts()
            if self[part] then
                self[part](self, v.id, parts)
            else
                print('ignoring component: ', v.id)
            end
        end
    end

    return self
end

function Zentropy.db.Components:get_door(open, dir, mask, rng)
    open = open or 'open'
    if not self.doors[open] then
        return
    end
    if not self.doors[open][dir] then
        return
    end
    local entries = {}
    for _, entry in pairs(self.doors[open][dir]) do
        if bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function Zentropy.db.Components:get_filler(mask, rng)
    local entries = {}
    for _, entry in pairs(self.fillers) do
        if bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

function Zentropy.db.Components:get_treasure(open, mask, rng)
    open = open or 'open'
    print(string.format('get_treasure %s %06o', open, mask))
    if not self.treasures[open] then
        print('treasure no open ' .. open)
        return
    end
    local entries = {}
    for _, entry in pairs(self.treasures[open]) do
        if entry.mask == 'any' then
            print(string.format('  check mask %s', entry.mask))
        else
            print(string.format('  check mask %06o', entry.mask))
        end
        if entry.mask == 'any' then
            for _, section in ipairs(self.SECTION_MASKS) do
                if bit32.band(mask, section) == 0 then
                    table.insert(entries, {mask=section, id=entry.id})
                end
            end
        elseif bit32.band(mask, entry.mask) == 0 then
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return
    end
    local entry = entries[rng:random(#entries)]
    return entry.id, entry.mask
end

return Zentropy