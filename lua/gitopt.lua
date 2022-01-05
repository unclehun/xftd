--[[
  clarkewanglei@gmail.com
--]]


require("fileopt")
require("map")

cloned = map:new()

function gitclone(gitdir, sourcesbase, modulename, gitaddr, modulepath, df_git_user, df_git_user_pwd) 
  --如果模块的git地址跟其它已经拉完代码的模块git一样,则不再重复拉代码
  local gitsrc = gitaddr
  if(nil ~= cloned:getpair(gitsrc)) then 
    local codepath = cloned:getpair(gitsrc)
    if(nil ~= modulepath) then
      codepath = codepath.."/"..modulepath
    end
 
    print('\n')
    print('no git clone,load from cache,git addr:'..gitsrc..' codepath:'..codepath)
    print('\n')

    return codepath
  end
      
  local dpc = gitdir..'/git --version'
  --print(dpc)
  local t= io.popen(dpc)
  local a = t:read("*all")
  print(a)

  --git config --global user.name   xxx
  --git config --global user.email   xxx@xx.com

  local rp = sourcesbase.."/"..modulename..'_'..os.time()
  local rpp = rp
  dpc = "rm -rf "..rp
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

  --print(gitaddr)
  gitaddr = string.gsub(gitaddr, "^[ \t\n\r]+", "").." "..rp
  print(gitaddr)
  gitaddrp=string.gsub(gitaddr,'git +clone',gitdir..'/git clone')..''
  gitaddrp=string.gsub(gitaddrp,'https://','https://'..df_git_user..':'..df_git_user_pwd..'@')..''
  gitaddrp=string.gsub(gitaddrp,'http://','http://'..df_git_user..':'..df_git_user_pwd..'@')..''
  print(gitaddrp)

  t = io.popen(gitaddrp)
  a = t:read("*all")
  print(a)

  if(nil ~= modulepath) then
    rp = rp.."/"..modulepath
  end
  dpc = "ls "..rp
  print(dpc)
  t = io.popen(dpc)
  a = t:read("*all")
  print(a)

  cloned:insert(gitsrc,rpp)
  return rp
end