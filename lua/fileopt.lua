--[[
  clarkewanglei@gmail.com
--]]


function writefile(path, content, mode)
  mode = mode or "w+b"
  local file = io.open(path, mode)
  if file then
    if file:write(content) == nil then return false end
    io.close(file)
    return true
  else
    return false
  end
end

function readfile(path)
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    io.close(file)
    return content
  end
  return nil
end

function fileExists(path)
  local file = io.open(path, "r")
  if file then
    io.close(file)
    return true
  end
  return false
end

function delFile(file)
  --print(os.remove(file))
  os.remove(file)
end

function length_of_file(filename)
  local fh = assert(io.open(filename, "rb"))
  local len = assert(fh:seek("end"))
  fh:close()
  return len
end