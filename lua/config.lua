--[[
  clarkewanglei@gmail.com
--]]

require("map")
require("list")
require("fileopt")
--require("lfs")
require("commonutils")

--require("buildopt")

local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")


--business modules{module_name->[c_name,type,git_src,git_path,build_cmd,service_port,[rel1,rel2,...],[depend1,depend2,...]]}
local bms = map:new()

--base modules{module_name->[c_name,image_tmpl,[rel1,rel2,...],[depend1,depend2,...]]}
local bbms = map:new()

--system name
local sysname

--if build for product env
local buildprod = false

--{db_name->[host,port,root,pwd,[[createusername,pwd,targetdb],[createusername,pwd,targetdb],...]}
local dbs = map:new()





--online package temp store path
local transpath

--online product path exec path
local prodpath

--online product backup path
local bkpath

--online logs root path
local logroot

--online module start script
--{module_type_name->{start script text}}
local startscript = map:new()

--online module stop script
--{module_type_name->{stop script text}}
local stopscript = map:new()

--online module restart script
--{module_type_name->{restart script text}}
local restartscript = map:new()

--module host mapping
--{module_name->{[host:user:type:startscript:stopscript:restartscript],[host:user:type:startscript:stopscript:restartscript]...}}
local modulehost = map:new()



local dulicatename = map:new()

local parsed = false

function parseConfig(configPath)

  if(parsed) then
    --if(true == parsed) then
    print('have parsed.')
    return 
  end
 
  xml = readfile(configPath)
  --print(xml)
  
  --Instantiates the XML parser
  parser = xml2lua.parser(handler)
  parser:parse(xml)

  sysname = handler.root.xml.sysname

  local bps = handler.root.xml.buildprod
  if("true" == bps) then
    buildprod = true
  end

  --buildprod = handler.root.xml.buildprod

  --Manually prints the table (since the XML structure for this example is previously known)
  
  local ttb = singletocollection(handler.root.xml.business.modules.module, 'business.modules.module')
  for i, p in pairs(ttb) do
    tdata = List:New()
    reldata = List:New()
    depdata = List:New()
    --print(i, "name:", p.name, "cname:", p.cname, "imagetmpl:", p.imagetmpl, "src:", p.src, "path:", p.path, "buildcmd:", p.buildcmd, "p.buildcmdpd:", p.buildcmdpd, "rels:", p.rels, "depends:", p.depends)
    if(isduplicate(p.cname)) then
    --if(true == isduplicate(p.cname)) then
      print('ERR:duplicate module name or cname:'..p.cname)
      --os.exit()
      return -1
    end
    tdata:Add(p.cname)
    tdata:Add(p.imagetmpl)
    local psrc = p.src:match("^[%s]*(.-)[%s]*$")
    tdata:Add(psrc)
    if(nil~=p.path) then
      tdata:Add(p.path)
    else
      tdata:Add('')
    end
    tdata:Add(p.buildcmd)
    tdata:Add(string.gsub(p.buildcmdpd, "^[ \t\n\r]+", ""))

    if(nil ~= p.rels) then
      if ('table' == type(p.rels.rel)) then
        for j, q in pairs(p.rels.rel) do 
          --print(j, p.name, "rels:", q, "type of q", type(q))
          reldata:Add(q)
        end
      else
        --print("rel:", p.rels.rel)
        reldata:Add(p.rels.rel)
      end
    end

    tdata:Add(reldata)

    if(nil ~= p.depends) then
      if('table' == type(p.depends.depend)) then
        for j, q in pairs(p.depends.depend) do 
          --print(j, p.name, "depends:", q, "type of q", type(q))
          depdata:Add(q)
        end
      else
        --print("depend:", p.depends.depend)
        depdata:Add(p.depends.depend)
      end
    end
    tdata:Add(depdata)

    if(isduplicate(p.name)) then
    --if(true == isduplicate(p.name)) then
      print('ERR:duplicate module name or cname:'..p.name)
      --os.exit()
      return -1
    end

    bms:insert(p.name,tdata)
  end
  
  if(nil ~= handler.root.xml.base) then
    local ttb = singletocollection(handler.root.xml.base.modules.module, 'base.modules.module')
    for i, p in pairs(ttb) do
      tdata = List:New()
      reldata = List:New()
      depdata = List:New()
      --print(i, "name:", p.name, "cname:", p.cname, "imagetmpl:", p.imagetmpl, "rels:", p.rels, "depends:", p.depends)
      if(isduplicate(p.cname)) then
      --if(true == isduplicate(p.cname)) then
        print('ERR:duplicate module name or cname:'..p.cname)
        --os.exit()
        return -1
      end    
      tdata:Add(p.cname)
      --根据imagetmpl获取imageversion

      tdata:Add(p.imagetmpl)

      if(nil ~= p.rels) then
        if('table' == type(p.rels.rel)) then
          for j, q in pairs(p.rels.rel) do 
            --print(j, "rel:", q)
            reldata:Add(q)
          end
        else
          --print("rel:", p.rels.rel)
          reldata:Add(p.rels.rel)
        end
      end
      tdata:Add(reldata)

      if(nil ~= p.depends) then
        if('table' == type(p.depends.depend)) then
          for j, q in pairs(p.depends.depend) do 
            --print(j, "depend:", q)
            depdata:Add(q)
          end
        else
          --print("depend:", p.depends.depend)
          depdata:Add(p.depends.depend)
        end
      end
      tdata:Add(depdata)

      if(isduplicate(p.name)) then
      --if(true == isduplicate(p.name)) then
        print('ERR:duplicate module name or cname:'..p.name)
        --os.exit()
        return -1
      end

      bbms:insert(p.name,tdata)
    end    
  end

  if(nil ~= handler.root.xml.dbtransfer) then
    local ttb = singletocollection(handler.root.xml.dbtransfer.dbs.db, 'dbtransfer.dbs.db')
    for i, p in pairs(ttb) do
      tdata = List:New()
      --print(i, "name:", p.name, "host:", p.host, "port:", p.port, "root:", p.root, "pwd:", p.pwd, "createusers:", p.createusers)
      tdata:Add(p.host)
      tdata:Add(p.port)
      tdata:Add(p.root)
      tdata:Add(p.pwd)
    
      createusers = List:New()
      if(nil ~= p.createusers) then
        local ttb = singletocollection(p.createusers.user, 'dbtransfer.dbs.db.createusers.user')

        for j, q in pairs(ttb) do 
          --print(j, "user:", q)
          if(nil ~= q) then 
            --print(q.acc,q.pwd,q.gdb)
            local user = List:New()
            user:Add(q.acc)
            user:Add(q.pwd)
            user:Add(q.gdb)
            createusers:Add(user)
          end
        end
      
      end

      tdata:Add(createusers)
      dbs:insert(p.name,tdata)
      --print(tdata:Count())
    end    
  end



  if(nil ~= handler.root.xml.goonline) then
    transpath = handler.root.xml.goonline.transpath
    prodpath = handler.root.xml.goonline.prodpath
    bkpath = handler.root.xml.goonline.bkpath
    logroot = handler.root.xml.goonline.logroot
  
    local ttbstop = singletocollection(handler.root.xml.goonline.stop.cmd, 'goonline.stop.cmd')
    for i, p in pairs(ttbstop) do
      stopscript:insert(p.name,p.sp)
    end
    
    local ttbstart = singletocollection(handler.root.xml.goonline.start.cmd, 'goonline.start.cmd')
    for i, p in pairs(ttbstart) do
      startscript:insert(p.name,p.sp)
    end
    
    local ttbrestart = singletocollection(handler.root.xml.goonline.restart.cmd, 'goonline.restart.cmd')
    for i, p in pairs(ttbrestart) do
      restartscript:insert(p.name,p.sp)
    end
    
    local ttbnode = singletocollection(handler.root.xml.goonline.nodes.node, 'goonline.nodes.node')
    for i, p in pairs(ttbnode) do
      local ttbnmm = singletocollection(p.modules.module, 'goonline.nodes.node.modules.module')
      for j, q in pairs(ttbnmm) do 
        local mhe = modulehost:getpair(q.name)
        local logpath = ''
        if(nil ~= q.logpath) then
          logpath = q.logpath
        end
        local depolypath = ''
        if(nil ~= q.depolypath) then
          depolypath = q.depolypath
        end
        if(nil ~= mhe) then
          --print(q.name, 'add host user to modulehost')
          mhe:Add(p.host..':'..p.port..':'..p.user..':'..q.type..':'..q.start..':'..q.stop..':'..q.restart..':'..logpath..':'..depolypath)
        else
          --print(q.name, 'create host user put to modulehost')          
          mhe = List:New()
          mhe:Add(p.host..':'..p.port..':'..p.user..':'..q.type..':'..q.start..':'..q.stop..':'..q.restart..':'..logpath..':'..depolypath)
        end

        modulehost:insert(q.name,mhe)
      end
    end
  else
    print('no goonline config found.')
  end  

  parsed = true
end

function isduplicate(name)
  if(nil ~= dulicatename:getpair(name)) then
    --print('dupicate:',name)
    return true
  else
    --print('not dupicate:',name)
    dulicatename:insert(name,1)
    return false
  end
end

--0:singel 1:multi
function singleormulti(ele)
  if 'table' ~= type(ele) then
    return 0
  end

  for k,v in pairs(ele) do 
    --print('singleormulti kv:',k,v)
    if 'table' ~= type(v) then
      return 0
    end
  end

  return 1
end

function singletocollection(ele,name)
  local somi = singleormulti(ele)
  --print(name..' singleormulti:',somi)
  if(0==somi) then
    ele={ele}
  end

  return ele
end

function isTable (value)
  if type(value) ~= "table" then
    value={}
  end

  return value
end

function countNums(t)
  local count = 0
  local t = isTable(t)

  for k, v in pairs(t) do
    count = count + 1
  end

  return count
end

function getsysname() 
  return sysname
end

function getbuildprod()
  return buildprod
end

function getbizmodules() 
  return bms
end

function getbasemodules() 
  return bbms
end

function getdbtransfer() 
  return dbs
end

function getbizmodulescount()
  local cct = 0
  if(nil ~= getbizmodules()) then
    for k,v in pairs(getbizmodules()) do
      if("count" ~= k and "point" ~= k) then
        cct = cct + 1
      end
    end  
  end

  return cct
end

function gettranspath()
  return transpath
end

function getprodpath()
  return prodpath
end

function getbkpath()
  return bkpath
end

function getlogroot()
  return logroot
end

function getstartscript()
  return startscript
end

function getstopscript()
  return stopscript
end

function getrestartscript()
  return restartscript
end

function getmodulehost()
  return modulehost
end