--[[
  clarkewanglei@gmail.com
--]]

require("fileopt")
require("map")
require("list")

require("config")

require("commonutils")

--bizmodulesimages {modulename->imagename} 
function makeDockercomposeConfig(xftdconfig,drdir,dccfp,tmpbase)
  local configcontent = List:New()

  local code = parseConfig(xftdconfig)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end

  local sysname = getsysname()

  configcontent:Add('  #'..sysname..' docker-compose config \n')
  configcontent:Add('  version: "3" \n')
  configcontent:Add('  services: \n')

  print("sysname:",sysname)

  local basemodules = getbasemodules()
  local businessmodules = getbizmodules()
  local moduleports = map:new()

  for k,v in pairs(basemodules) do
    if("count" ~= k and "point" ~= k) then
      local modulename=v[1]
      local cname = v[2][1]
      local imagetmpl = v[2][2]

      local tmplf = 'docker_image_config/'..imagetmpl..'.dic'
      local ports = getmoduleinnerport(tmplf)
      print('moduleports',modulename,ports)
      moduleports:insert(modulename,ports)
    end
  end

  for k,v in pairs(businessmodules) do
    if("count" ~= k and "point" ~= k) then
      local modulename=v[1]
      local cname = v[2][1]
      local imagetmpl = v[2][2]

      local tmplf = 'docker_image_config/'..imagetmpl..'.dic'
      local ports = getmoduleinnerport(tmplf)
      print('moduleports',modulename,ports)
      moduleports:insert(modulename,ports)
    end    
  end
  
  for k,v in pairs(basemodules) do
    if("count" ~= k and "point" ~= k) then
      --print(v[1],v[2][1],v[2][2])

      local modulename=v[1]
      local cname = v[2][1]
      local imagetmpl = v[2][2]
      --print(k,cname,imagetmpl)

      local rels = v[2][3]
      local relsc = ''
      if(nil ~= rels) then
        for j, q in pairs(rels) do 
          --print(j, modulename, "rels ele:", q, "type of q:", type(q))
          relsc = relsc..'  - '..q..' \n         '
        end
        if(''~=relsc) then relsc = string.gsub(relsc,'\n +$','') end
      end

      local depends = v[2][4]
      local dependsc = ''
      local dependdt = ''
      if(nil ~= depends) then
        for j, q in pairs(depends) do 
          --print(j, "depends ele:", q, "type of q:", type(q))
          dependsc = dependsc..'  - '..q..' \n         '
          --根据$depends算出$dependdt
          local ports = moduleports:getpair(q)
          --print(q,ports)
          for x, z in pairs(ports) do 
            dependdt = dependdt..q..':'..z..','
          end
        end

        if(''~=dependsc) then dependsc = string.gsub(dependsc,'\n +$','') end

        if ''~=dependdt then
          dependdt = string.sub(dependdt, 1, -2) 
          print('dependdt',dependdt)
        end        
      end

      local tmplf = 'docker_image_config/'..imagetmpl..'.dic'
      configcontent:Add('    '..modulename..':\n')
      local itmplp = processtmpl(tmplf, cname, modulename, relsc, dependsc, drdir, dependdt, tmpbase)
      configcontent:Add(itmplp..'\n\n')

    end
  end
  
  for k,v in pairs(businessmodules) do
    if("count" ~= k and "point" ~= k) then
      --print(v[1],v[2][1],v[2][2])

      local modulename=v[1]
      local cname = v[2][1]
      local imagetmpl = v[2][2]
      local src = v[2][3]
      local path = v[2][4]
      local bcmd = v[2][5]
      --local bcmdpd = v[2][6]
      --print(k,cname,imagetmpl,src,path,bcmd)

      local rels = v[2][7]
      local relsc = ''
      if(nil ~= rels) then
        for j, q in pairs(rels) do 
          --print(j, modulename, "rels ele:", q, "type of q:", type(q))
          relsc = relsc..'  - '..q..' \n         '
        end
        if(''~=relsc) then relsc = string.gsub(relsc,'\n +$','') end
      end

      local depends = v[2][8]
      local dependsc = ''
      local dependdt = ''
      if(nil ~= depends) then
        for j, q in pairs(depends) do 
          --print(j, modulename, "depends ele:", q, "type of q:", type(q))
          dependsc = dependsc..'  - '..q..' \n         '
          --根据$depends算出$dependdt
          local ports = moduleports:getpair(q)
          print('q,ports:',q,ports)
          for x, z in pairs(ports) do 
            dependdt = dependdt..q..':'..z..','
          end
        end
        if(''~=dependsc) then dependsc = string.gsub(dependsc,'\n +$','') end
        
        if ''~=dependdt then
          dependdt = string.sub(dependdt, 1, -2) 
          print('dependdt',dependdt)
        end
      end

      if(startswith(imagetmpl, 'springboot')) then 
        --local tmplfs = 'docker_image_config/springboot.dic'
        local tmplfs = 'docker_image_config/'..imagetmpl..'.dic'
        configcontent:Add('    '..modulename..':\n')
        local itmplsp = processtmpl(tmplfs, cname, modulename, relsc, dependsc, drdir, dependdt,tmpbase)
        configcontent:Add(itmplsp..'\n\n')
      elseif(startswith(imagetmpl, 'vuepkg')) then
        --local tmplfv = 'docker_image_config/vuepkg.dic'
        local tmplfv = 'docker_image_config/'..imagetmpl..'.dic'
        configcontent:Add('    '..modulename..':\n')
        local itmplsvp = processtmpl(tmplfv, cname, modulename, relsc, dependsc, drdir, dependdt,tmpbase)
        configcontent:Add(itmplsvp..'\n\n')
      else
        print('not supported!')
        return
      end

    end
  end

  configf=''
  for j,q in pairs(configcontent) do
    configf = configf..q
  end
  print(configf)
  
  print('dccfp:',dccfp)
  writefile(dccfp,configf) 
  
end

function getmoduleinnerport(tmplf)
  --print("tmplf", tmplf)
  local rslt = List:New()

  local g = 0
  for l in io.lines(tmplf) do
    if g == 0 then
      if nil ~= string.match(l, "ports:") then 
        g = 1
      end
    else
      local mr = string.match(l, "%d+ *: *%d+")
      local mrs = string.match(l, "%d+")
      --print(mr) 
      --print(mrs)
      if(nil == mr and nil == mrs)then 
        g = 0
      else
        --print(l)
        
        if(nil ~= mr) then
          local idx = string.find(mr,':',0,true)
          local rs = string.sub(mr,idx+1)
          --rr为外部端口
          local rr = string.sub(mr,1,idx-1)
          print('outter port:'..rr)
          rs = string.gsub(rs,"\"","")
          print('inner port:'..rs)
          rslt:Add(rs)        
        elseif(nil ~= mrs) then
          local rs = string.gsub(mrs,"\"","")
          print('inner port:'..rs)
          rslt:Add(rs)        
        end
  
      end
      
    end
  end

  return rslt
end

function processtmpl(tmplfs, cname, modulename, relsc, dependsc, drdir, dependdt, tmpbase)
  --local tmplfs = 'docker_image_config/springboot.dic'
  local itmpls = readfile(tmplfs)

  itmpls = string.gsub(itmpls,"$cname",cname)
  itmpls = string.gsub(itmpls,"$imagename",modulename..'_di')
  if('' ~= relsc) then
    itmpls = string.gsub(itmpls,"$links",relsc)
  end
  if('' ~= dependsc) then
    itmpls = string.gsub(itmpls,"$depends",dependsc)
    itmpls = string.gsub(itmpls,"$dependdt",dependdt)
  end      
  itmpls = string.gsub(itmpls,"$drdir",drdir)

  local sbtt = tmpbase..'/sbtt'
  writefile(sbtt,itmpls)
  local listt = List:New()
  local listn = List:New()
  for l in io.lines(sbtt) do
    local signal = false
    if('' == relsc) then
      -- 是否有要删除的link* 有,直接跳过该行
      --if(true == string.contains(l,'links:') or true == string.contains(l,'$links')) then
      if(string.contains(l,'links:') or string.contains(l,'$links')) then
        print('del line rel:'..l)
        signal = true
      end
    end
    --if(false == signal and '' == dependsc) then
    if((not signal) and '' == dependsc) then
      -- 是否有要删除的depend* 有,直接跳过该行
      --if(true == string.contains(l,'depends_on:') or true == string.contains(l,'$depends') or (true == string.contains(l,'entrypoint:') and true == string.contains(l,'$dependdt'))) then
      if(string.contains(l,'depends_on:') or string.contains(l,'$depends') or (string.contains(l,'entrypoint:') and string.contains(l,'$dependdt'))) then
        print('del line dep:'..l)
        signal = true
      end            
    end
    --if(false == signal) then 
    if(not signal) then 
      listn:Add(l..'\n')
    end
  end
  delFile(sbtt)
  local itmplsp = ''
  for j, q in pairs(listn) do 
    itmplsp = itmplsp..q
  end
  --print("itmplsp:"..itmplsp)
  
  return itmplsp
end