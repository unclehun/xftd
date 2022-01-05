--[[
  clarkewanglei@gmail.com
--]]

List = {}
List.__index = List
function List:New(t)
    local o = {itemType = t}
    setmetatable(o, self)
    return o
end

function List:Add(item)
    table.insert(self, item)
end

function List:Clear()
    local count = self:Count()
    for i = count, 1, -1 do
        table.remove(self)
    end
end

function List:Contains(item)
    local count = self:Count()
    for i = 1, count do
        if self[i] == item then
            return true
        end
    end
    return false
end

function List:Count()
    return #self
end

function List:Find(predicate)
    if (predicate == nil or type(predicate) ~= "function") then
        print("predicate is invalid!")
        return
    end
    local count = self:Count()
    for i = 1, count do
        if predicate(self[i]) then
            return self[i]
        end
    end
    return nil
end

function List:ForEach(action)
    if (action == nil or type(action) ~= "function") then
        print("action is invalid!")
        return
    end
    local count = self:Count()
    for i = 1, count do
        action(self[i])
    end
end

function List:IndexOf(item)
    local count = self:Count()
    for i = 1, count do
        if self[i] == item then
            return i
        end
    end
    return 0
end

function List:LastIndexOf(item)
    local count = self:Count()
    for i = count, 1, -1 do
        if self[i] == item then
            return i
        end
    end
    return 0
end

function List:Insert(index, item)
    table.insert(self, index, item)
end

function List:ItemType()
    return self.itemType
end

function List:Remove(item)
    local idx = self:LastIndexOf(item)
    if (idx > 0) then
        table.remove(self, idx)
        self:Remove(item)
    end
end

function List:RemoveAt(index)
    table.remove(self, index)
end

function List:Sort(comparison)
    if (comparison ~= nil and type(comparison) ~= "function") then
        print("comparison is invalid")
        return
    end
    if func == nil then
        table.sort(self)
    else
        table.sort(self, func)
    end
end





Dictionary = {}
Dictionary.__index = Dictionary

function Dictionary:New(tk, tv)
    local o = {keyType = tk, valueType = tv}
    setmetatable(o, self)
    o.keyList = {}
    return o
end

function Dictionary:Add(key, value)
    if self[key] == nil then
        self[key] = value
        table.insert(self.keyList, key)
    else
        self[key] = value
    end
end

function Dictionary:Clear()
    local count = self:Count()
    for i = count, 1, -1 do
        self[self.keyList[i]] = nil
        table.remove(self.keyList)
    end
end

function Dictionary:ContainsKey(key)
    local count = self:Count()
    for i = 1, count do
        if self.keyList[i] == key then
            return true
        end
    end
    return false
end

function Dictionary:ContainsValue(value)
    local count = self:Count()
    for i = 1, count do
        if self[self.keyList[i]] == value then
            return true
        end
    end
    return false
end

function Dictionary:Count()
    return #(self.keyList)
end

function Dictionary:Iter()
    local i = 0
    local n = self:Count()
    return function()
        i = i + 1
        if i <= n then
            return self.keyList[i]
        end
        return nil
    end
end

function Dictionary:Remove(key)
    if self:ContainsKey(key) then
        local count = self:Count()
        for i = 1, count do
            if self.keyList[i] == key then
                table.remove(self.keyList, i)
                break
            end
        end
        self[key] = nil
    end
end

function Dictionary:KeyType()
    return self.keyType
end

function Dictionary:ValueType()
    return self.valueType
end
