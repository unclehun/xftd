--[[
  clarkewanglei@gmail.com
--]]

function startswith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function endswith(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function string.contains(str, item)
    local t = {}
    local l = {}
    local index = 0
    for i = 1, string.len(str) do
        table.insert(t, string.byte(string.sub(str, i, i)))
    end

    for i = 1, string.len(item) do
        table.insert(l, string.byte(string.sub(item, i, i)))
    end
    if #l > #t then
        return false
    end

    for k, v1 in pairs(t) do
        index = index + 1
        if v1 == l[1] then
            local iscontens = true
            for i = 1, #l do
                if t[index + i - 1] ~= l[i] then
                    iscontens = false
                end
            end
            if iscontens then
                return iscontens
            end
        end
    end
    return false
end

function string:split(inSplitPattern, outResults)
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end