map = {}

--local this = map

function map:new()
    o = {}
    setmetatable(o,self)
    self.__index = self
    self.count = 0
    self.point = 1
    return o
end

function map:isempty()
  if(0 == self.count) then
    return true
  else
   return false
  end
end

function map:insert(k,v)
    local sted = false
    for kk,_ in pairs(self) do
        if nil ~= self[kk] then
            if("count" ~= kk and "point" ~= kk) then
              if(self[kk][1] == k) then
                  --print('update',k)
                  self[kk][2] = v
                  sted = true
              end
            end
        end
    end

    if(not sted) then
    --if(false == sted) then
        --print('new',k)
        self[self.point] = {k,v}
        self.point = self.point + 1
        self.count = self.count + 1
    end
end

function map:remove(k)
    if self.count <=0 then
      return
    else
      self.count = self.count - 1
    end

    for kk,_ in pairs(self) do
        if nil ~= self[kk] then
            if("count" ~= kk and "point" ~= kk) then
              if(self[kk][1] == k) then
                self[kk] = nil
              end
            end
        end
    end
end

function map:getpair(k)
    local value = nil
    
    for kk,_ in pairs(self) do
        if nil ~= self[kk] then
            if("count" ~= kk and "point" ~= kk) then
              if(self[kk][1] == k) then
                value = self[kk][2]
              end
            end
        end
    end
    
    return value
end

function map:clear()
    for k,_ in pairs(self) do
        if nil ~= self[k] then
            self[k] = nil
        end
    end
    self.count = 0
end