--[[
  clarkewanglei@gmail.com
--]]
package.path = package.path .. ';../?.lua'

require("lfs")
require("fileopt")
require("config")
require("gitopt")
require("buildopt")
require("dockeropt")
require("dockercomposeopt")
require("transferdb")

require("mainconfig")

--根据配置文件:拉取代码,编译打包,生成docker镜像,生成dockercompose文件,启动docker容器
function createSystem(config,xftdroot,confighisbase,releasebase)
  print("create system with "..config)
  --if(false == fileExists(config)) then
  if(not fileExists(config)) then
    print('ERR:'..config ..' not found')
    return
  end
  
  --解析配置文件
  local code = parseConfig(config)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end

  local sysname = getsysname();
  sysname = string.gsub(sysname, "^[ \t\n\r]+", "")
  sysname = string.gsub(sysname, " ","_")
  local statusfile = confighisbase..'/'..sysname..'_status.dat'
  --if(false == processSysStatus(sysname,confighisbase,'create',statusfile)) then
  if(not processSysStatus(sysname,confighisbase,'create',statusfile)) then
    return
  end

  createSystemin(config,xftdroot,confighisbase,releasebase)
  --生成docker-compose文件
  local dccft = confighisbase..'/docker-compose-'..sysname..'.yml'
  delFile(dccft)
  makeDockercomposeConfig(config, docker_mappingbase, dccft, tmp_base)

  writefile(statusfile,'CREATED')
  
  print('\n')
  print('########################################################')
  print('\n')
  print('It seems success to create '..sysname)
  print('\n')
  print('########################################################')
  print('\n')
end


function createSystemin(config,xftdroot,confighisbase, releasebase)
  --解析配置文件
  local code = parseConfig(config)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end  

  local businessmodules = getbizmodules()
  local sysname = getsysname()
  local cct = getbizmodulescount()

  local cctt = 1
  
  --清理上线包保存目录
  local dpc = 'rm -rf '..releasebase..'/*'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  
  --清理MAVEN本地库
  local dpc = 'rm -rf '..xftdroot..'/lua/mvn_repon_temp/*'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)  
  
  for k,v in pairs(businessmodules) do
    if("count" ~= k and "point" ~= k) then
      --print(v[1],v[2][1],v[2][2])
      
      local modulename=v[1]
      local cname = v[2][1]
      local imagetmpl = v[2][2]
      local src = v[2][3]
      local path = v[2][4]
      local bcmd = v[2][5]
      local bcmdpd = v[2][6]
      
      print('\n################################\n')
      print('  '..modulename..' '..cctt..'/'..cct)
      print('\n################################\n')
      cctt=cctt+1      

      print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
      print('modulename:',modulename)
      print('cname:',cname)
      print('imagetmpl:',imagetmpl)
      print('src:',src)
      print('path:',path)      
      print('bcmd:',bcmd)
      print('bcmdpd:',bcmdpd)
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')

      --拉代码编译
      local fromdisk = false
      local codepath
      -----###test code------
      --if(true == fromdisk) then
      if(fromdisk) then
        if('portial' ~= modulename) then
          
          codepath = '/Users/wanglei/Documents/xftd/sourcesbase/homeins-user-service_1631590974/'
          if(nil ~= path) then
            codepath = codepath.."/"..path
          end
        else
          
          codepath = '/Users/wanglei/Documents/xftd/sourcesbase/portial_1631591366/'
        end
      -----###test code------
      else
        codepath = gitclone(git_dir,sources_base,modulename,src,path,git_user,git_user_pwd)
      end

      local cmds = bcmd:split(';')
      local cmdpds = bcmdpd:split(';')

      local bbin = build(modulename, cmds, cmdpds, mvn_base, gradle_base, java_base, node_base, codepath, releasebase, getbuildprod(),tmp_base)
      local releasepath = bbin[2]
      local releasefile = bbin[1]
      
      local entrypointsh = xftd_root..'/lua/dtsh/entrypoint.sh'
      local nginxdefaultconfig = xftd_root..'/lua/dtsh/nginx_config_router'
      local telnet = xftd_root..'/lua/docker_image_config/telnet_0.17-42_amd64.deb'
      
      --打包测试环境docker镜像
      if(startswith(imagetmpl, 'springboot')) then 
        buildimagemini(releasepath,releasefile,'9527',modulename..'_di',entrypointsh,telnet) --容器内端口可写死
      elseif(startswith(imagetmpl, 'vuepkg')) then
        buildimageftmini(string.gsub(releasepath,'/dist%.test',''),'dist.test','8088',modulename..'_di',entrypointsh,nginxdefaultconfig,telnet) --容器内端口可写死
      else
        print('unsupport imagetmpl:'..imagetmpl)
        os.exit()
      end
      
    end
  end
  
end

--使用配置文件重新生成dockercompose文件,并重置系统状态为CREATED
function createSystemUdi(config,xftdroot,confighisbase)
  print("create system use docker image with "..config)
  --if(false == fileExists(config)) then
  if(not fileExists(config)) then
    print('ERR:'..config ..' not found')
    return
  end

  --解析配置文件
  local code = parseConfig(config)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  
  local sysname = getsysname();
  sysname = string.gsub(sysname, "^[ \t\n\r]+", "")
  sysname = string.gsub(sysname, " ","_")  
  local statusfile = confighisbase..'/'..sysname..'_status.dat'
  --if(false == processSysStatus(sysname,confighisbase,'create',statusfile)) then
  if(not processSysStatus(sysname,confighisbase,'create',statusfile)) then
    return
  end
  
  --生成docker-compose文件
  local dccft = confighisbase..'/docker-compose-'..sysname..'.yml'
  delFile(dccft)
  makeDockercomposeConfig(config, docker_mappingbase, dccft, tmp_base)
  writefile(statusfile,'CREATED')
  
  print('\n')
  print('########################################################')
  print('\n')
  print('It seems success to create '..sysname)
  print('\n')
  print('########################################################')
  print('\n')  
end

--删除全部模块的docker容器,删除dockercompose配置文件,删除系统状态文件
function delSystem(systemname,confighisbase)
  print("delete system "..systemname)
    
  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local statusfile = confighisbase..'/'..snme..'_status.dat'
  --if(false == processSysStatus(snme,confighisbase,'del',statusfile)) then
  if(not processSysStatus(snme,confighisbase,'del',statusfile)) then
    return
  end
  
  local dccft = confighisbase..'/docker-compose-'..snme..'.yml'
  --if(false == fileExists(dccft)) then
  if(not fileExists(dccft)) then
    print('ERR:'..systemname..' not created('..dccft..' not found)')
    return
  end

  --删除容器docker
  local dpc = 'docker-compose -f '..dccft..' down'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  
  --删除docker-compose-config文件
  delFile(dccft)
  

  ---#######TODO 删除容器外映射的文件########-----
  ---#######TODO 删除docker内的镜像文件#####-----
end

--使用dockercompose文件启动全部模块的容器
function startSystem(systemname,confighisbase)
  print("start system "..systemname)
  
  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local statusfile = confighisbase..'/'..snme..'_status.dat'  
  local dccft = confighisbase..'/docker-compose-'..snme..'.yml'
  --if(false == fileExists(dccft)) then
  if(not fileExists(dccft)) then
    print('ERR:'..systemname..' not created('..dccft..' not found)')
    return
  end
  --if(false == processSysStatus(snme,confighisbase,'start',statusfile)) then
  if(not processSysStatus(snme,confighisbase,'start',statusfile)) then
    return
  end

  --清理none镜像
  --docker image prune -f
  local dpc = 'docker image prune -f'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  --writefile(statusfile,'RUNNING')

  --启动docker
  dpc = "docker-compose -f "..dccft.." --compatibility up -d"
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  writefile(statusfile,'RUNNING')
end

--使用dockercompose文件,启动某一个模块的容器
function startSystemModule(systemname,modulename,confighisbase)
  print("start system:"..systemname.." module:"..modulename)
  
  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local statusfile = confighisbase..'/'..snme..'_status.dat'  
  local dccft = confighisbase..'/docker-compose-'..snme..'.yml'
  --if(false == fileExists(dccft)) then
  if(not fileExists(dccft)) then
    print('ERR:'..systemname..' not created('..dccft..' not found)')
    return
  end

  --清理none镜像
  --docker image prune -f
  local dpc = 'docker image prune -f'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)

  dpc = 'docker-compose -f '..dccft..' --compatibility start '..modulename
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
end

--停止全部模块docker容器
function stopSystem(systemname,confighisbase)
  print("stop system "..systemname)
    
  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local dccft = confighisbase..'/docker-compose-'..snme..'.yml'
  local statusfile = confighisbase..'/'..snme..'_status.dat'  
  --if(false == fileExists(dccft)) then
  if(not fileExists(dccft)) then
    print('ERR:'..systemname..' not created('..dccft..' not found)')
    return
  end
  --if(false == processSysStatus(snme,confighisbase,'stop')) then
  if(not processSysStatus(snme,confighisbase,'stop')) then
    return
  end

  --停止容器docker
  local dpc = 'docker-compose -f '..dccft..' --compatibility stop'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  writefile(statusfile,'STOPPED')
end

--使用dockercompose文件,停止某一个模块的容器
function stopSystemModule(systemname,modulename,confighisbase)
  print("stop system:"..systemname..' module:'..modulename)
   
  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local dccft = confighisbase..'/docker-compose-'..snme..'.yml'
  local statusfile = confighisbase..'/'..snme..'_status.dat'  
  --if(false == fileExists(dccft)) then
  if(not fileExists(dccft)) then
    print('ERR:'..systemname..' not created('..dccft..' not found)')
    return
  end

  local dpc = 'docker-compose -f '..dccft..' --compatibility stop '..modulename
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)     
end

--使用dockercompose文件,重启全部模块的容器
function restartSystem(systemname,confighisbase)
  print("restart system "..systemname)
  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local statusfile = confighisbase..'/'..snme..'_status.dat'  
  --if(false == processSysStatus(snme,confighisbase,'restart',statusfile)) then
  if(not processSysStatus(snme,confighisbase,'restart',statusfile)) then
    return
  end

  stopSystem(systemname,confighisbase)
  startSystem(systemname,confighisbase)
  writefile(statusfile,'RUNNING')
end

--使用dockercompose文件,重启某一个模块的容器
function restartSystemModule(systemname,confighisbase,modulename)
  print('restart system '..systemname..' :'..modulename)
    
  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local dccft = confighisbase..'/docker-compose-'..snme..'.yml'
  local statusfile = confighisbase..'/'..snme..'_status.dat'  
  --if(false == fileExists(dccft)) then
  if(not fileExists(dccft)) then
    print('ERR:'..systemname..' not created('..dccft..' not found)')
    return
  end
  --if(not processSysStatus(systemname,confighisbase,'restart',statusfile)) then
  --  return
  --end  
  
  --重启某一个容器docker
  local dpc = 'docker-compose -f '..dccft..' --compatibility stop '..modulename
  --local dpc = 'docker-compose -f '..dccft..' --compatibility up -d'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  
  dpc = 'docker-compose -f '..dccft..' --compatibility start '..modulename
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  --writefile(statusfile,'RUNNING')
end

--重新拉代码,编译,打包镜像,重新启动docker容器
function updateSystem(config, xftdroot, confighisbase, releasebase)
  print("update system with "..config)
  --if(false == fileExists(config)) then
  if(not fileExists(config)) then
    print('ERR:'..config ..' not found')
    return
  end

  --解析配置文件
  local code = parseConfig(config)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  sysname = string.gsub(sysname, " ","_")  
  local statusfile = confighisbase..'/'..sysname..'_status.dat'
  --if(false == processSysStatus(sysname,confighisbase,'update',statusfile)) then
  if(not processSysStatus(sysname,confighisbase,'update',statusfile)) then
    return
  end

  local dccft = confighisbase..'/docker-compose-'..sysname..'.yml'
  --如果系统在启动状态则停止
  local fcc = readfile(statusfile)
  local rc = false
  if('RUNNING' == fcc) then 
    rc = true
    stopSystem(systemname,confighisbase)
  end
  --删除容器docker
  local dpc = 'docker-compose -f '..dccft..' --compatibility down'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  --删除docker-compose-config文件
  delFile(dccft)

  --###TODO 找出哪些变化过的做更新,还是整体一起更新?
  createSystemin(config,xftdroot,confighisbase,releasebase)
  --生成docker-compose文件
  delFile(dccft)
  makeDockercomposeConfig(config, docker_mappingbase, dccft, tmp_base)

  --if(true == rc) then
  if(rc) then
    startSystem(systemname,confighisbase)
  end

  print('\n')
  print('########################################################')
  print('\n')
  print('It seems update success '..systemname)
  print('\n')
  print('########################################################')
  print('\n')  
end

--更新某些模块代码,配置,重新拉代码，打包，生成docker镜像,重启docker容器
function updateModules(configfile,modulenames,confighisbase,releasebase)
  print('update module ['..modulenames..'] with '..configfile)
  --if(false == fileExists(configfile)) then
  if(not fileExists(configfile)) then
    print('ERR:'..configfile ..' not found')
    return
  end

  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end

  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  sysname = string.gsub(sysname, " ","_")  
  local statusfile = confighisbase..'/'..sysname..'_status.dat'
  local fcc = readfile(statusfile)
  local rc = false
  if('RUNNING' == fcc) then 
    rc = true
  end

  --if(not processSysStatus(sysname,confighisbase,'update',statusfile)) then
  --  return
  --end
  
  local businessmodules = getbizmodules()
  local basemodules = getbasemodules()

  ---多个模块处理循环开始
  modulenames = string.gsub(modulenames, "^[ \t\n\r]+", "")
  local mnames = modulenames:split(',')
  local rsf = false
  for k,v in pairs(mnames) do
    --print(k,v)
    local modulename = v
    
    local bizm = businessmodules:getpair(modulename)
    local basem = basemodules:getpair(modulename)

    if(nil == basem and nil == bizm) then
      print('ERR:module not found:'..modulename)
      return
    end

    if(nil ~= basem) then
      print('\n########################################################\n')
      print(modulename..' is an base module,use reconfig to update it.')
      print('\n########################################################\n')
    end
  
    if(nil ~= bizm) then
      rsf = true
      local cname = bizm[1]
      local imagetmpl = bizm[2]
      local src = bizm[3]
      local path = bizm[4]
      local bcmd = bizm[5]
      local bcmdpd = bizm[6]

      print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
      print('modulename:',modulename)
      print('cname:',cname)
      print('imagetmpl:',imagetmpl)
      print('src:',src)
      print('path:',path)      
      print('bcmd:',bcmd)
      print('bcmdpd:',bcmdpd)
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
      
      --拉代码
      --编译
      --打docker镜像
      --重启指定module 
      local codepath = gitclone(git_dir,sources_base,modulename,src,path,git_user,git_user_pwd)

      local cmds = bcmd:split(';')
      local cmdpds = bcmdpd:split(';')

      local bbin = build(modulename,cmds, cmdpds, mvn_base, gradle_base, java_base, node_base, codepath, releasebase, getbuildprod(),tmp_base)
      local releasepath = bbin[2]
      local releasefile = bbin[1]
      
      local entrypointsh = xftd_root..'/lua/dtsh/entrypoint.sh'
      local nginxdefaultconfig = xftd_root..'/lua/dtsh/nginx_config_router'
      local telnet = xftd_root..'/lua/docker_image_config/telnet_0.17-42_amd64.deb'

      --打包测试docker镜像
      if(startswith(imagetmpl, 'springboot')) then 
        buildimagemini(releasepath,releasefile,'9527',modulename..'_di',entrypointsh,telnet) --容器内端口可写死
      elseif(startswith(imagetmpl, 'vuepkg')) then
        buildimageftmini(string.gsub(releasepath,'/dist%.test',''),'dist.test','8088',modulename..'_di',entrypointsh,nginxdefaultconfig,telnet) --容器内端口可写死
      else
        print('unsupport imagetmpl:'..imagetmpl)
        os.exit()
      end
    end  
  end
  ---多个模块处理循环结束    

  if(true == rsf) then
    local dccft = confighisbase..'/docker-compose-'..sysname..'.yml'
    delFile(dccft)
    makeDockercomposeConfig(config, docker_mappingbase, dccft, tmp_base)

    --更新容器
    if(true == rc) then
      local dpc1 = 'docker-compose -f '..dccft..' --compatibility up -d'
      local t1 = io.popen(dpc1)
      print(dpc1)
      local a1 = t1:read("*all")
      print(a1)
    end  
  end

  print('\n')
  print('########################################################')
  print('\n')
  print('It seems update module success. '..modulenames)
  print('\n')
  print('########################################################')
  print('\n')
  
end

--显示系统和docker容器状态
function showsstatus(systemname,confighisbase,statusfile)
  print('showsstatus system '..systemname)

  local snme = string.gsub(systemname, "^[ \t\n\r]+", "")
  snme = string.gsub(snme, " ","_")
  local dccft = confighisbase..'/docker-compose-'..snme..'.yml'
  local statusfile = confighisbase..'/'..snme..'_status.dat'
  --if(false == fileExists(dccft) or false == fileExists(statusfile)) then
  if(not fileExists(dccft) or not fileExists(statusfile)) then
    print('ERR:'..systemname..' is not created('..dccft..';'..statusfile..' not found)')
    return
  end

  local fcc = readfile(statusfile)
  print('\n')
  print('###################################')
  print('\n')
  print(systemname..' status:'..fcc)
  print('\n')
  print('###################################')
  print('\n')

  local dpc = 'docker-compose -f '..dccft..' ps'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
end

--根据配置文件重新生成dockercompose文件,重启全部模块的docker容器
function reconfig(configfile,confighisbase)
  print("reconfig system with "..configfile)
  --if(false == fileExists(configfile)) then
  if(not fileExists(configfile)) then
    print('ERR:'..configfile ..' not found')
    return
  end

  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  sysname = string.gsub(sysname, " ","_")  
  local statusfile = confighisbase..'/'..sysname..'_status.dat'

  local dccft = confighisbase..'/docker-compose-'..sysname..'.yml'
  --如果系统在启动状态则停止
  local fcc = readfile(statusfile)
  local rc = false
  if('RUNNING' == fcc) then 
    rc = true
  end

  delFile(dccft)
  makeDockercomposeConfig(config, docker_mappingbase, dccft, tmp_base)
  --if(true == rc) then
  if(rc) then
    local dpc1 = 'docker-compose -f '..dccft..' --compatibility up -d'
    local t1 = io.popen(dpc1)
    print(dpc1)
    local a1 = t1:read("*all")
    print(a1)    
  end
end

function processSysStatus(systemname,confighisbase,opt,statusfile)
  if(nil == opt) then
    print('ERR:invalid opt. '..opt)
    return flase
  end

  --local snme = systemname
  local statusfile = confighisbase..'/'..systemname..'_status.dat'
  local ise = fileExists(statusfile)
  local fcc
  --if(true == ise) then
  if(ise) then
    fcc = readfile(statusfile)
  end
  if('create' == opt) then
    --if(true == ise) then
    if(ise) then
      print('ERR:system '..systemname..' is already existed.')
      return false
    else
      --writefile(statusfile,'CREATED')
      return true
    end
  elseif('start' == opt) then
    --if(false == ise) then
    if(not ise) then
      print('ERR:system '..systemname..' is not existed.')
      return false      
    end
    if('CREATED' == fcc or 'STOPPED' == fcc or 'RUNNING' == fcc) then
       --writefile(statusfile,'RUNNING')
      return true
    else
      print('ERR:system '..systemname..' is not in proper status. '..fcc)
      return false        
    end
  elseif('stop' == opt) then
    --if(false == ise) then
    if(not ise) then
      print('ERR:system '..systemname..' is not existed.')
      return false      
    end
    if('RUNNING' == fcc) then
      --writefile(statusfile,'STOPPED')
      return true      
    else
      print('ERR:system '..systemname..' is not in proper status. '..fcc)
      return false       
    end
  elseif('restart' == opt) then
    --if(false == ise) then
    if(not ise) then
      print('ERR:system '..systemname..' is not existed.')
      return false      
    end
    if('RUNNING' == fcc or 'STOPPED' == fcc) then
      --writefile(statusfile,'RUNNING')
      return true      
    else
      print('ERR:system '..systemname..' is not in proper status. '..fcc)
      return false       
    end    
  elseif('del' == opt) then
    delFile(statusfile)
    return true
  elseif('update' == opt) then
    --if(false == ise) then
    if(not ise) then
      print('ERR:system '..systemname..' is not existed.')
      return false      
    end
    if('CREATED' == fcc or 'RUNNING' == fcc or 'STOPPED' == fcc) then
      return true      
    else
      print('ERR:system '..systemname..' is not in proper status. '..fcc)
      return false       
    end          
  else
    print('ERR:unsupport operation. '..status)
    return false
  end
end

--初始化数据库,从目标库导入数据
function initdb(config,mysqlbase,tmpbase,sdbname,dbtt,tdbname,nocsb)
  --解析配置文件
  local code = parseConfig(config)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end

  local sdb,shost,sroot,sport,spwd,spath,tdb,thost,troot,tport,tpwd
  local dbtransfer = getdbtransfer()
  if(nil ~= dbtransfer and false == dbtransfer:isempty()) then  
    for k,v in pairs(dbtransfer) do
      if("count" ~= k and "point" ~= k) then
        print(v[1],v[2][1],v[2][2],v[2][3],v[2][4],v[2][5])
        if(sdbname == v[1]) then
          shost = v[2][1]
          sroot = v[2][3]
          sport = v[2][2]
          spwd = v[2][4]
        end
        if(tdbname == v[1]) then
          thost = v[2][1]
          troot = v[2][3]
          tport = v[2][2]
          tpwd = v[2][4]
        end        
      end
    end
  else
    print('ERR:dbtransfer config not found.')
    return
  end

  for i = 1, #dbtt do
    print('\n')
    print(sdbname..'.'..dbtt[i]..'----------------------->'..tdbname..'.'..dbtt[i]..'.............')
    print('\n')
    sdb = dbtt[i]
    tdb = dbtt[i]
    spath = tmpbase..'/db/'..sdb..'.sql'
    transferDatabase(mysqlbase,sdb,shost,sroot,sport,spwd,spath,tdb,thost,troot,tport,tpwd,nocsb)
  end

  print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
  print('transfer complete login ['..tdbname..'.'..tdb..'] to to check the data.')
  print('\n')
  print('if you see an error like this: ERROR 1840 (HY000) at line 27: @@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_EXECUTED is empty.')
  print('\n')
  print('do following thing:\n')
  print('1.copy this to commandline and execute:'..mysqlbase..'/mysql -h'..thost..' -P'..tport..' -uroot'..' -p'..tpwd)
  print('2.copy this to commandline and execute:'..'reset master;')
  print('3.copy this to commandline and execute:'..'exit')
  print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
  
end

--创建数据库初始用户
function initdbuser(configfile,xftdroot,mysqlbase,tdb)
  print('tdb',tdb)
  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end

  local dbtransfer = getdbtransfer()
  if(nil ~= dbtransfer and false == dbtransfer:isempty()) then 
    for k,v in pairs(dbtransfer) do
      if("count" ~= k and "point" ~= k) then
        if(v[1] == tdb and nil ~=v[2][5]) then
          local thost,troot,tport,tpwd
          thost = v[2][1]
          troot = v[2][3]
          tport = v[2][2]
          tpwd = v[2][4]         
          if(nil ~= v[2][5] and 0 ~= v[2][5]:Count()) then
            for j,q in pairs(v[2][5]) do
              print("init user:",q[1],q[2],q[3])

              --../mysqlbin/mysql -h127.0.0.1 -uroot -p123456 -P3307 目标数据库(可空)<~/Documents/xftd/mysql_create_user/create_user.sql
              local cuf = xftdroot..'/mysql_create_user/create_user.sql'
              cus = readfile(cuf)
              print(1,cus);
              cus = string.gsub(cus,"$c_user",q[1])
              print(2,cus);
              cus = string.gsub(cus,"$c_pwd",q[2])
              print(3,cus);
              delFile(cuf..'.m')
              writefile(cuf..'.m',cus)
              local dpc = mysqlbase..'/mysql -h'..thost..' -u'..troot..' -p'..tpwd..' -P'..tport..' <'..cuf..'.m'
              print(dpc)
              print('initing ['..tdb..'] user ['..q[1]..'] .................')
              local t = io.popen(dpc)
              local a = t:read("*all")
              print(a);
            end
          else
            print('ERR: no user to init.')
          end
        end
      end     
    end
  else
    print('ERR: no user to init.')
  end  
end

function releaseol(configfile,modulename,releasebase)
  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  print('modulename:',modulename)
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  
  local prodpath = getprodpath()
  print('prodpath:',prodpath)
  local bkpath = getbkpath()
  print('bkpath:',bkpath)
  local transpath = gettranspath()
  print('transpath:',transpath)
  local logroot = getlogroot()
  print('logroot:',logroot)

  local mhm = getmodulehost()
  local mhc = mhm:getpair(modulename)
  if(nil == mhc) then
    print('ERR:invalid modulename:'..modulename)
    return    
  end
  
  local startscriptmap = getstartscript()
  local stopscriptmap = getstopscript()
  local restartscriptmap = getrestartscript()
  local vertime = os.date("%Y%m%d%H%M%S",unixtime)
  print('\n vertime:'..vertime..'\n')

  for j, q in pairs(mhc) do 
    --print(modulename..':','host:'..q)
    --host:port:user:type:startscript:stopscript:restartscript
    local mhi = q:split(':')
    local host = mhi[1]
    print('host:',host)
    local port = mhi[2]
    print('port:',port)    
    local user = mhi[3]
    print('user:',user)
    local type = mhi[4]
    print('type:',type)
    local startst = startscriptmap:getpair(mhi[5])
    --print('startscript:',startst)
    local stopst = stopscriptmap:getpair(mhi[6])
    --print('stopscript:',stopst)
    local restartst = restartscriptmap:getpair(mhi[7])
    --print('restartscript:',restartst)
    local logpath = mhi[8]
    logpath = string.gsub(logpath,"${logroot}",logroot)
    print('logpath:',logpath)
    local depolypath= mhi[9]
    print('depolypath:',depolypath)

    local answer
    repeat
      io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
      io.write('will releasae new version of ('..modulename..') to ['..host..']'..' ,are you sure to do that.(y/n)?')
      io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
      io.flush()
      answer=io.read()
    until answer=="y" or answer=="n"
    if(answer=="n") then
      return
    end

    print('release ('..modulename..') to ['..host..'] start...')
    
    local mrlspath = releasebase..'/'..modulename..'/'

    if('sb' == type) then
      --springboot 项目
      print(modulename..'-->springboot module')
      
      --脚本0,清理transpath    
      local scriptclean = 'if [ ! -d "'..transpath..'/'..modulename..'" ];then\n'
      scriptclean = scriptclean..'mkdir -p '..transpath..'/'..modulename..'\n'
      scriptclean = scriptclean..'else\n'
      scriptclean = scriptclean..'rm -rf '..transpath..'/'..modulename..'/*\n'
      scriptclean = scriptclean..'fi\n'    

      local dpc = 'ssh -t -p '..port..' '..user..'@'..host..' <<res\n'..scriptclean..'res'
      local t = io.popen(dpc)
      print(dpc)
      print('\n################# waiting authentication to do clean...........................\n')
      local a = t:read("*all")
      print(a)

      --脚本1,初始化目录
      local scriptinit = '#!/bin/bash\n'
      scriptinit = scriptinit..'if [ ! -d "'..bkpath..'" ];then\n'
      scriptinit = scriptinit..'mkdir '..bkpath..'\n'
      scriptinit = scriptinit..'fi\n'
    
      scriptinit = scriptinit..'if [ ! -d "'..prodpath..'" ];then\n'
      scriptinit = scriptinit..'mkdir '..prodpath..'\n'
      scriptinit = scriptinit..'fi\n'
    
      scriptinit = scriptinit..'if [ ! -d "'..logroot..'" ];then\n'
      scriptinit = scriptinit..'mkdir '..logroot..'\n'
      scriptinit = scriptinit..'fi\n'    

      writefile(mrlspath..'init.sh',scriptinit)  
    
      --脚本2,重命名,对比sha256签名
      local scriptcfp = '#!/bin/bash\n'
      scriptcfp = scriptcfp..'mv '..transpath..'/'..modulename..'/*.jar '..transpath..'/'..modulename..'/'..modulename..'_'..vertime..'.jar\n'
      scriptcfp = scriptcfp..'cat '..transpath..'/'..modulename..'/fp.txt | awk -F \' \' \'{print $1}\'\n'
      scriptcfp = scriptcfp..'shasum -a 256 '..transpath..'/'..modulename..'/'..modulename..'_'..vertime..'.jar'
      writefile(mrlspath..'cfp.sh',scriptcfp)

      --脚本3,备份
      local scriptbk =  '#!/bin/bash\n'
      scriptbk = scriptbk..'version="$1"\n'
      scriptbk = scriptbk..'mkdir -p '..bkpath..'/'..modulename..'/${version}/\n'
      scriptbk = scriptbk..'cp -r '..prodpath..'/'..modulename..'/* '..bkpath..'/'..modulename..'/${version}/\n'
      --scriptbk = scriptbk..'rm -rf '..prodpath..'/'..modulename..'/*'
      writefile(mrlspath..'bk.sh',scriptbk)
    
      --脚本4,停止服务
      local scriptst = '#!/bin/bash\n'
      scriptst = scriptst..string.gsub(stopst,"${module}",modulename..'.jar')
      writefile(mrlspath..'stop.sh',scriptst)
    
      --脚本5,部署新包
      local scriptnr =  '#!/bin/bash\n'
      local logpathp = string.match(logpath, "(.+)/[^/]*%.%w+$")
      scriptnr = scriptnr..'if [ ! -d "'..prodpath..'/'..modulename..'" ];then\n'
      scriptnr = scriptnr..'mkdir '..prodpath..'/'..modulename..'\n'
      scriptnr = scriptnr..'fi\n'
      scriptnr = scriptnr..'if [ ! -d "'..logpathp..'" ];then\n'
      scriptnr = scriptnr..'mkdir '..logpathp..'\n'
      scriptnr = scriptnr..'fi\n'    
      scriptnr = scriptnr..'rm -rf '..prodpath..'/'..modulename..'/*\n'
      scriptnr = scriptnr..'cp -r '..transpath..'/'..modulename..'/* '..prodpath..'/'..modulename..'/\n'
      scriptnr = scriptnr..'mv '..prodpath..'/'..modulename..'/'..modulename..'_'..vertime..'.jar '..prodpath..'/'..modulename..'/'..modulename..'.jar'
      writefile(mrlspath..'dp.sh',scriptnr)

      --脚本6,启动服务
      local scriptsta = '#!/bin/bash\n'
      local tmpsta = string.gsub(startst,"${module}",modulename..'.jar')
      tmpsta = string.gsub(tmpsta,"${modulef}",prodpath..'/'..modulename..'/'..modulename..'.jar')
      scriptsta = scriptsta..tmpsta
      writefile(mrlspath..'start.sh',scriptsta)

      --脚本7,回滚服务
      local scriptrb = '#!/bin/bash\n'
      scriptrb = scriptrb..'version="$1"\n'
      --scriptrb = scriptrb..string.gsub(stopst,"${module}",modulename..'.jar')..'\n'
      scriptrb = scriptrb..'sh '..prodpath..'/'..modulename..'/stop.sh\n'
      scriptrb = scriptrb..'rm -rf '..prodpath..'/'..modulename..'/*\n'
      scriptrb = scriptrb..'cp -r '..bkpath..'/'..modulename..'/${version}/* '..prodpath..'/'..modulename..'/\n' 
      --scriptrb = scriptrb..string.gsub(startst,"${module}",prodpath..'/'..modulename..'/'..modulename..'.jar')
      scriptrb = scriptrb..'sh '..prodpath..'/'..modulename..'/start.sh'
      writefile(mrlspath..'rollbk.sh',scriptrb)

      --脚本8,重启服务
      local scriptrs = '#!/bin/bash\n'
      local tmpsc = string.gsub(restartst,"${module}",modulename..'.jar')
      tmpsc = string.gsub(tmpsc,"${modulef}",prodpath..'/'..modulename..'/'..modulename..'.jar')
      scriptrs = scriptrs..tmpsc
      writefile(mrlspath..'restart.sh',scriptrs)

      --脚本9,获取本次部署启动日志信息
      local scriptfl = '#!/bin/bash\n'
      scriptfl = scriptfl..' sleep 35\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs start...#############################\'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs last 200 lines #############################\'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' tail -n 200 '..logpath..'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs errors brief last 500 lines #############################\'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' tail -n 500 '..logpath..' | grep -n -C 10 -e "Exception" -e "Error"\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs end   #############################\'\n'
      scriptfl = scriptfl..' echo \'\''
      writefile(mrlspath..'fetchlog.sh',scriptfl)
      
      --脚本10,检查模块状态
      local scriptck = '#!/bin/bash\n'
      scriptck = scriptck..'echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"\n'
      scriptck = scriptck..'ps -ef|grep '..modulename..'.jar\n'
      scriptck = scriptck..'echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"'
      writefile(mrlspath..'checkstatus.sh',scriptck)     

      --copy上线的包和相关脚本到线上机器
      --dpc = 'scp -v -P '..port..' '..mrlspath..'/* '..user..'@'..host..':'..transpath..'/'..modulename
      dpc = 'scp -P '..port..' '..mrlspath..'/* '..user..'@'..host..':'..transpath..'/'..modulename
      t = io.popen(dpc)
      print(dpc)
      print('\n################ waiting authentication to copy release to online...........................\n')
      a = t:read("*all")
      print(a)
    
      --检查文件指纹是否一致
      dpc = 'ssh -t -p '..port..' '..user..'@'..host..' sh '..transpath..'/'..modulename..'/cfp.sh'
      t = io.popen(dpc)
      print(dpc)
      print('\n################ waiting authentication to check release fingerprint..........................\n')
      a = t:read("*all")
      print(a)    
     
      local answer1
      repeat
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.write('Is the file fingerprint is same?(y/n)?')
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.flush()
        answer1=io.read()
      until answer1=="y" or answer1=="n"
      if(answer1=="n") then
        os.exit()
        --return
      end
    
      --备份目前运行包
      --停止服务
      --部署新的上线包
      --启动服务
      dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..transpath..'/'..modulename..'/init.sh;'
      dpc = dpc..'sh '..transpath..'/'..modulename..'/stop.sh;' 
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/stop.sh;'    
      dpc = dpc..'sh '..transpath..'/'..modulename..'/bk.sh '..vertime..';'
      dpc = dpc..'sh '..transpath..'/'..modulename..'/dp.sh;'
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/start.sh;'
      --检查日志,端口启动后等待35秒
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/fetchlog.sh"'
      t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to depoly and restart...........................\n')
      a = t:read("*all")
      print(a)
    
      local answer2
      repeat
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.write('Is the new release of ('..modulename..') seems normal?(y/n)?')
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.flush()
        answer2=io.read()
      until answer2=="y" or answer2=="n"
      if(answer2=="n") then
        --回滚  
        print('\n-------rollback start.............-----------\n')
        dpc = 'ssh -p '..port..' '..user..'@'..host..' '
        dpc = dpc..'"sh '..prodpath..'/'..modulename..'/rollbk.sh '..vertime..';'
        dpc = dpc..'sh '..prodpath..'/'..modulename..'/fetchlog.sh"' 
        t = io.popen(dpc)
        print(dpc)
        print('\n####################### waiting authentication to rollback to previous version........................\n')
        a = t:read("*all")
        print(a)
        print('\n-------rollback end -------------------------\n')
        os.exit()
      end    
    
      print('release ('..modulename..') to ['..host..'] end...')      
    elseif('vu1' == type) then
      --vue项目
      print(modulename..'-->vue module')
      
      --脚本0,清理transpath    
      local scriptclean = 'if [ ! -d "'..transpath..'/'..modulename..'" ];then\n'
      scriptclean = scriptclean..'mkdir -p '..transpath..'/'..modulename..'\n'
      scriptclean = scriptclean..'else\n'
      scriptclean = scriptclean..'rm -rf '..transpath..'/'..modulename..'/*\n'
      scriptclean = scriptclean..'fi\n'    

      local dpc = 'ssh -t -p '..port..' '..user..'@'..host..' <<res\n'..scriptclean..'res'
      local t = io.popen(dpc)
      print(dpc)
      print('\n################# waiting authentication to do clean...........................\n')
      local a = t:read("*all")
      print(a)

      --脚本1,初始化目录
      local scriptinit = '#!/bin/bash\n'
      scriptinit = scriptinit..'if [ ! -d "'..bkpath..'" ];then\n'
      scriptinit = scriptinit..'mkdir '..bkpath..'\n'
      scriptinit = scriptinit..'fi\n'
    
      scriptinit = scriptinit..'if [ ! -d "'..depolypath..'" ];then\n'
      scriptinit = scriptinit..'mkdir '..depolypath..'\n'
      scriptinit = scriptinit..'fi\n'   

      writefile(mrlspath..'init.sh',scriptinit)  
    
      --脚本2,重命名,对比sha256签名
      local scriptcfp = '#!/bin/bash\n'
      scriptcfp = scriptcfp..'mv '..transpath..'/'..modulename..'/*.tar.gz '..transpath..'/'..modulename..'/'..modulename..'_'..vertime..'.tar.gz\n'
      scriptcfp = scriptcfp..'cat '..transpath..'/'..modulename..'/fp.txt | awk -F \' \' \'{print $1}\'\n'
      scriptcfp = scriptcfp..'shasum -a 256 '..transpath..'/'..modulename..'/'..modulename..'_'..vertime..'.tar.gz'
      writefile(mrlspath..'cfp.sh',scriptcfp)

      --脚本3,备份
      local scriptbk =  '#!/bin/bash\n'
      scriptbk = scriptbk..'version="$1"\n'
      scriptbk = scriptbk..'mkdir -p '..bkpath..'/'..modulename..'/${version}/\n'
      scriptbk = scriptbk..'cp -r '..depolypath..'/* '..bkpath..'/'..modulename..'/${version}/\n'
      writefile(mrlspath..'bk.sh',scriptbk)
      
      --脚本4,停止服务
      local scriptst = '#!/bin/bash\n'
      scriptst = scriptst..string.gsub(stopst,"${module}",modulename)
      writefile(mrlspath..'stop.sh',scriptst)

      --脚本5,部署新包
      local scriptnr =  '#!/bin/bash\n'   
      scriptnr = scriptnr..'rm -rf '..depolypath..'/*\n'
      scriptnr = scriptnr..'cp -r '..transpath..'/'..modulename..'/* '..depolypath..'/\n'
      scriptnr = scriptnr..'mv '..depolypath..'/'..modulename..'_'..vertime..'.tar.gz '..depolypath..'/'..modulename..'.tar.gz\n'
      scriptnr = scriptnr..'cd '..depolypath..'&&tar -xzvf '..modulename..'.tar.gz\n'
      scriptnr = scriptnr..'rm -rf '..depolypath..'/'..modulename..'.tar.gz\n'
      scriptnr = scriptnr..'mv '..depolypath..'/dist/* '..depolypath..'\n'
      scriptnr = scriptnr..'rm -rf '..depolypath..'/dist'
      writefile(mrlspath..'dp.sh',scriptnr)

      --脚本6,启动服务
      local scriptsta = '#!/bin/bash\n'
      local tmpsta = string.gsub(startst,"${module}",modulename)
      scriptsta = scriptsta..tmpsta
      writefile(mrlspath..'start.sh',scriptsta)

      --脚本7,回滚服务
      local scriptrb = '#!/bin/bash\n'
      scriptrb = scriptrb..'version="$1"\n'
      scriptrb = scriptrb..'sh '..depolypath..'/stop.sh\n'
      scriptrb = scriptrb..'rm -rf '..depolypath..'/*\n'
      scriptrb = scriptrb..'cp -r '..bkpath..'/'..modulename..'/${version}/* '..depolypath..'/\n' 
      scriptrb = scriptrb..'sh '..depolypath..'/start.sh'
      writefile(mrlspath..'rollbk.sh',scriptrb)
      
      --脚本8,重启服务
      local scriptrs = '#!/bin/bash\n'
      local tmpsc = string.gsub(restartst,"${module}",modulename)
      scriptrs = scriptrs..tmpsc
      writefile(mrlspath..'restart.sh',scriptrs)

      --脚本9,获取本次部署启动日志信息
      local scriptfl = '#!/bin/bash\n'
      scriptfl = scriptfl..' sleep 5\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs start...#############################\'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs last 200 lines #############################\'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' tail -n 200 '..logpath..'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs errors brief last 500 lines #############################\'\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' tail -n 500 '..logpath..' | grep -n -C 10 -e "Exception" -e "Error"\n'
      scriptfl = scriptfl..' echo \'\'\n'
      scriptfl = scriptfl..' echo \'#######################start logs end   #############################\'\n'
      scriptfl = scriptfl..' echo \'\''
      writefile(mrlspath..'fetchlog.sh',scriptfl)
      
      --脚本10,检查模块状态
      local scriptck = '#!/bin/bash\n'
      scriptck = scriptck..'echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"\n'
      scriptck = scriptck..'ps -ef|grep nginx\n'
      scriptck = scriptck..'echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"'
      writefile(mrlspath..'checkstatus.sh',scriptck)     

      --copy上线的包和相关脚本到线上机器
      dpc = 'scp -P '..port..' '..mrlspath..'/* '..user..'@'..host..':'..transpath..'/'..modulename
      t = io.popen(dpc)
      print(dpc)
      print('\n################ waiting authentication to copy release to online...........................\n')
      a = t:read("*all")
      print(a)
    
      --检查文件指纹是否一致
      dpc = 'ssh -t -p '..port..' '..user..'@'..host..' sh '..transpath..'/'..modulename..'/cfp.sh'
      t = io.popen(dpc)
      print(dpc)
      print('\n################ waiting authentication to check release fingerprint..........................\n')
      a = t:read("*all")
      print(a)    
     
      local answer1
      repeat
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.write('Is the file fingerprint is same?(y/n)?')
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.flush()
        answer1=io.read()
      until answer1=="y" or answer1=="n"
      if(answer1=="n") then
        os.exit()
        --return
      end
    
      --备份目前运行包
      --停止服务
      --部署新的上线包
      --启动服务
      dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..transpath..'/'..modulename..'/init.sh;'
      dpc = dpc..'sh '..transpath..'/'..modulename..'/stop.sh;'
      dpc = dpc..'sh '..depolypath..'/stop.sh;'    
      dpc = dpc..'sh '..transpath..'/'..modulename..'/bk.sh '..vertime..';'
      dpc = dpc..'sh '..transpath..'/'..modulename..'/dp.sh;'
      dpc = dpc..'sh '..depolypath..'/start.sh;'
      --检查日志,端口启动后等待5秒
      dpc = dpc..'sh '..depolypath..'/fetchlog.sh"'
      t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to depoly and restart...........................\n')
      a = t:read("*all")
      print(a)
    
      local answer2
      repeat
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.write('Is the new release of ('..modulename..') seems normal?(y/n)?')
        io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
        io.flush()
        answer2=io.read()
      until answer2=="y" or answer2=="n"
      if(answer2=="n") then
        --回滚  
        print('\n-------rollback start.............-----------\n')
        dpc = 'ssh -p '..port..' '..user..'@'..host..' '
        dpc = dpc..'"sh '..depolypath..'/rollbk.sh '..vertime..';'
        dpc = dpc..'sh '..depolypath..'/fetchlog.sh"' 
        t = io.popen(dpc)
        print(dpc)
        print('\n####################### waiting authentication to rollback to previous version........................\n')
        a = t:read("*all")
        print(a)
        print('\n-------rollback end -------------------------\n')
        os.exit()
      end    
    
      print('release ('..modulename..') to ['..host..'] end...')
    else
      --未知项目
      print('ERR:unsupport module type:'..type)
      os.exit()
    end
  end

end

function startol(configfile,modulename)
  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  print('modulename:',modulename)
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  
  local prodpath = getprodpath()
  print('prodpath:',prodpath)
  local bkpath = getbkpath()
  print('bkpath:',bkpath)
  local transpath = gettranspath()
  print('transpath:',transpath)
  local logroot = getlogroot()
  print('logroot:',logroot)

  local mhm = getmodulehost()
  local mhc = mhm:getpair(modulename)
  if(nil == mhc) then
    print('ERR:invalid modulename:'..modulename)
    return    
  end
  
  local startscriptmap = getstartscript()
  local stopscriptmap = getstopscript()
  local restartscriptmap = getrestartscript()

  for j, q in pairs(mhc) do 
    --print(modulename..':','host:'..q)
    --host:port:user:type:startscript:stopscript:restartscript
    local mhi = q:split(':')
    local host = mhi[1]
    print('host:',host)
    local port = mhi[2]
    print('port:',port)    
    local user = mhi[3]
    print('user:',user)
    local type = mhi[4]
    print('type:',type)
    local startst = startscriptmap:getpair(mhi[5])
    --print('startscript:',startst)
    local stopst = stopscriptmap:getpair(mhi[6])
    --print('stopscript:',stopst)
    local restartst = restartscriptmap:getpair(mhi[7])
    --print('restartscript:',restartst)
    local logpath = mhi[8]
    logpath = string.gsub(logpath,"${logroot}",logroot)
    print('logpath:',logpath)
    local depolypath= mhi[9]
    print('depolypath:',depolypath)      
    
    if('sb' == type) then
      --springboot 项目
      print(modulename..'-->springboot module')

      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..prodpath..'/'..modulename..'/start.sh;'
      --检查日志,端口启动后等待35秒
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to start ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a)      
    elseif('vu1' == type) then
      --vue项目
      print(modulename..'-->vue module')
      
      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..depolypath..'/start.sh;'
      --检查日志,端口启动后等待5秒
      dpc = dpc..'sh '..depolypath..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to start ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a) 
    else
      --未知项目
      print('ERR:unsupport module type:'..type)
      os.exit()
    end
  end 
end

function stopol(configfile,modulename)
  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  print('modulename:',modulename)
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  
  local prodpath = getprodpath()
  print('prodpath:',prodpath)
  local bkpath = getbkpath()
  print('bkpath:',bkpath)
  local transpath = gettranspath()
  print('transpath:',transpath)
  local logroot = getlogroot()
  print('logroot:',logroot)

  local mhm = getmodulehost()
  local mhc = mhm:getpair(modulename)
  if(nil == mhc) then
    print('ERR:invalid modulename:'..modulename)
    return    
  end
  
  local startscriptmap = getstartscript()
  local stopscriptmap = getstopscript()
  local restartscriptmap = getrestartscript()

  for j, q in pairs(mhc) do 
    --print(modulename..':','host:'..q)
    --host:port:user:type:startscript:stopscript:restartscript
    local mhi = q:split(':')
    local host = mhi[1]
    print('host:',host)
    local port = mhi[2]
    print('port:',port)    
    local user = mhi[3]
    print('user:',user)
    local type = mhi[4]
    print('type:',type)
    local startst = startscriptmap:getpair(mhi[5])
    --print('startscript:',startst)
    local stopst = stopscriptmap:getpair(mhi[6])
    --print('stopscript:',stopst)
    local restartst = restartscriptmap:getpair(mhi[7])
    --print('restartscript:',restartst)
    local logpath = mhi[8]
    logpath = string.gsub(logpath,"${logroot}",logroot)
    print('logpath:',logpath)
    local depolypath= mhi[9]
    print('depolypath:',depolypath)      
    
    if('sb' == type) then
      --springboot 项目
      print(modulename..'-->springboot module')

      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..prodpath..'/'..modulename..'/stop.sh;'
      --检查日志,端口启动后等待35秒
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to stop ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a)      
    elseif('vu1' == type) then
      --vue项目
      print(modulename..'-->vue module')
      
      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..depolypath..'/stop.sh;'
      --检查日志,端口启动后等待5秒
      dpc = dpc..'sh '..depolypath..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to stop ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a) 
    else
      --未知项目
      print('ERR:unsupport module type:'..type)
      os.exit()
    end
  end
end

function restartol(configfile,modulename)
  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  print('modulename:',modulename)
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  
  local prodpath = getprodpath()
  print('prodpath:',prodpath)
  local bkpath = getbkpath()
  print('bkpath:',bkpath)
  local transpath = gettranspath()
  print('transpath:',transpath)
  local logroot = getlogroot()
  print('logroot:',logroot)

  local mhm = getmodulehost()
  local mhc = mhm:getpair(modulename)
  if(nil == mhc) then
    print('ERR:invalid modulename:'..modulename)
    return    
  end
  
  local startscriptmap = getstartscript()
  local stopscriptmap = getstopscript()
  local restartscriptmap = getrestartscript()

  for j, q in pairs(mhc) do 
    --print(modulename..':','host:'..q)
    --host:port:user:type:startscript:stopscript:restartscript
    local mhi = q:split(':')
    local host = mhi[1]
    print('host:',host)
    local port = mhi[2]
    print('port:',port)    
    local user = mhi[3]
    print('user:',user)
    local type = mhi[4]
    print('type:',type)
    local startst = startscriptmap:getpair(mhi[5])
    --print('startscript:',startst)
    local stopst = stopscriptmap:getpair(mhi[6])
    --print('stopscript:',stopst)
    local restartst = restartscriptmap:getpair(mhi[7])
    --print('restartscript:',restartst)
    local logpath = mhi[8]
    logpath = string.gsub(logpath,"${logroot}",logroot)
    print('logpath:',logpath)
    local depolypath= mhi[9]
    print('depolypath:',depolypath)      
    
    if('sb' == type) then
      --springboot 项目
      print(modulename..'-->springboot module')

      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..prodpath..'/'..modulename..'/restart.sh;'
      --检查日志,端口启动后等待35秒
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to restart ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a)      
    elseif('vu1' == type) then
      --vue项目
      print(modulename..'-->vue module')
      
      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'"sh '..depolypath..'/restart.sh;'
      --检查日志,端口启动后等待5秒
      dpc = dpc..'sh '..depolypath..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to restart ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a) 
    else
      --未知项目
      print('ERR:unsupport module type:'..type)
      os.exit()
    end
  end   
end

function rollbackol(configfile,modulename,version)
    --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  print('modulename:',modulename)
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  
  local prodpath = getprodpath()
  print('prodpath:',prodpath)
  local bkpath = getbkpath()
  print('bkpath:',bkpath)
  local transpath = gettranspath()
  print('transpath:',transpath)
  local logroot = getlogroot()
  print('logroot:',logroot)

  local mhm = getmodulehost()
  local mhc = mhm:getpair(modulename)
  if(nil == mhc) then
    print('ERR:invalid modulename:'..modulename)
    return    
  end
  
  local startscriptmap = getstartscript()
  local stopscriptmap = getstopscript()
  local restartscriptmap = getrestartscript()

  local vertime = os.date("%Y%m%d%H%M%S",unixtime)
  print('\n vertime:'..vertime..'\n')

  for j, q in pairs(mhc) do 
    --print(modulename..':','host:'..q)
    --host:port:user:type:startscript:stopscript:restartscript
    local mhi = q:split(':')
    local host = mhi[1]
    print('host:',host)
    local port = mhi[2]
    print('port:',port)    
    local user = mhi[3]
    print('user:',user)
    local type = mhi[4]
    print('type:',type)
    local startst = startscriptmap:getpair(mhi[5])
    --print('startscript:',startst)
    local stopst = stopscriptmap:getpair(mhi[6])
    --print('stopscript:',stopst)
    local restartst = restartscriptmap:getpair(mhi[7])
    --print('restartscript:',restartst)
    local logpath = mhi[8]
    logpath = string.gsub(logpath,"${logroot}",logroot)
    print('logpath:',logpath)
    local depolypath= mhi[9]
    print('depolypath:',depolypath)     
    
    local answer
    repeat
      io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
      io.write('will rollback version ['..version..'] of ('..modulename..') to ['..host..']'..' ,are you sure to do that.(y/n)?')
      io.write('\n-------------------------------------------------------------------------------------------------------------------------\n')
      io.flush()
      answer=io.read()
    until answer=="y" or answer=="n"
    if(answer=="n") then
      return
    end    
    
    if('sb' == type) then
      --springboot 项目
      print(modulename..'-->springboot module')

      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      --停服务
      --备份
      --回滚至指定版本
      --启动服务
      dpc = dpc..'"sh '..prodpath..'/'..modulename..'/bk.sh '..vertime..';'
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/rollbk.sh '..version..';'
      --检查日志,端口启动后等待35秒
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to rollback ['..modulename..'] to ..('..version..').............................\n')
      local a = t:read("*all")
      print(a)      
    elseif('vu1' == type) then
      --vue项目
      print(modulename..'-->vue module')
      
      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      --停服务
      --备份
      --回滚至指定版本
      --启动服务
      dpc = dpc..'"sh '..depolypath..'/bk.sh '..vertime..';'
      dpc = dpc..'sh '..depolypath..'/rollbk.sh '..version..';'
      --检查日志,端口启动后等待5秒
      dpc = dpc..'sh '..depolypath..'/fetchlog.sh"'      
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to rollback ['..modulename..'] to ..('..version..').............................\n')
      local a = t:read("*all")
      print(a)       
    else
      --未知项目
      print('ERR:unsupport module type:'..type)
      os.exit()
    end
  end 
end

function showstatusol(configfile,modulename)
  --解析配置文件
  local code = parseConfig(configfile)
  if(-1 == code) then
    print('system exit.')
    os.exit()
  end
  print('modulename:',modulename)
  
  local systemname = getsysname();
  local sysname = string.gsub(systemname, "^[ \t\n\r]+", "")
  
  local prodpath = getprodpath()
  print('prodpath:',prodpath)
  local bkpath = getbkpath()
  print('bkpath:',bkpath)
  local transpath = gettranspath()
  print('transpath:',transpath)
  local logroot = getlogroot()
  print('logroot:',logroot)

  local mhm = getmodulehost()
  local mhc = mhm:getpair(modulename)
  if(nil == mhc) then
    print('ERR:invalid modulename:'..modulename)
    return    
  end
  
  local startscriptmap = getstartscript()
  local stopscriptmap = getstopscript()
  local restartscriptmap = getrestartscript()

  for j, q in pairs(mhc) do 
    --print(modulename..':','host:'..q)
    --host:port:user:type:startscript:stopscript:restartscript
    local mhi = q:split(':')
    local host = mhi[1]
    print('host:',host)
    local port = mhi[2]
    print('port:',port)    
    local user = mhi[3]
    print('user:',user)
    local type = mhi[4]
    print('type:',type)
    local startst = startscriptmap:getpair(mhi[5])
    --print('startscript:',startst)
    local stopst = stopscriptmap:getpair(mhi[6])
    --print('stopscript:',stopst)
    local restartst = restartscriptmap:getpair(mhi[7])
    --print('restartscript:',restartst)
    local logpath = mhi[8]
    logpath = string.gsub(logpath,"${logroot}",logroot)
    print('logpath:',logpath)
    local depolypath= mhi[9]
    print('depolypath:',depolypath)    
    
    if('sb' == type) then
      --springboot 项目
      print(modulename..'-->springboot module')

      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'sh '..prodpath..'/'..modulename..'/checkstatus.sh'
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to show status of ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a)      
    elseif('vu1' == type) then
      --vue项目
      print(modulename..'-->vue module')
      
      local dpc = 'ssh -p '..port..' '..user..'@'..host..' '
      dpc = dpc..'sh '..depolypath..'/checkstatus.sh'
      local t = io.popen(dpc)
      print(dpc)
      print('\n##################### waiting authentication to show status of ['..modulename..']...........................\n')
      local a = t:read("*all")
      print(a)       
    else
      --未知项目
      print('ERR:unsupport module type:'..type)
      os.exit()
    end
  end  
end

local usage='USAGE--\n'..
            '[help]\n'..
            '[create]      [systemconfigfile] [--udi(directly use docker image,no git clone source and no compile)]\n'..
            '[update]      [systemconfigfile]\n'..
            '[updatem]     [systemconfigfile] [modulename1,modulename2,...]]\n'..            
            '[del]         [systemname]\n'..
            '[start]       [systemname] [modulename(no specify will start whole system)]\n'..
            '[restart]     [systemname] [modulename(no specify will restart whole system)]\n'..
            '[stop]        [systemname] [modulename(no specify will stop whole system)]\n'..
            '[initdb]      [systemconfigfile] [sourcedb:database1,database2...] [targetdb] [nocs(with nocs means do not set --column-statistics=0 when mysqldump)]\n'..
            '[initdbuser]  [systemconfigfile] [dbname]\n'..
            '[status]      [systemname]\n'..
            '[reconfig]    [systemconfigfile]\n'..        
            '[ol]          [systemconfigfile] [r(release)/rb(rollback)/s(start)/st(stop)/rs(restart)/sts/(status)] [modulename] [version(rollback need specify)]\n'                        
            

function printenv()
  print('ENV:')
  print('xftd_root',xftd_root)
  print('java_base',java_base)
  print('sources_base',sources_base)
  print('mvn_base',mvn_base)
  print('gradle_base',gradle_base)
  print('docker_mappingbase',docker_mappingbase)
  print('node_base',node_base)
  print('mysqlclient_base',mysqlclient_base)
  print('config_his_base',config_his_base)
  print('config_release_base',config_release_base)
  print('tmp_base',tmp_base)
end


function main()
  local argslen = #arg

  local commandtype = arg[1]
  if(nil == commandtype) then
    print('ERR:invalid command.')
    print(usage)
    return
  end

  commandtype = string.gsub(commandtype, "^[ \t\n\r]+", "")
  if('create' == commandtype) then
    printenv()
    local configfile = arg[2]
    local udi = arg[3]
    if(nil == configfile) then
      print('no specify configfile will find default(xftdconfig.xml) in '..xftd_root)
      return
    else
      if('--udi' == udi) then
        createSystemUdi(configfile,xftd_root,config_his_base)
      else
        createSystem(configfile,xftd_root,config_his_base,config_release_base)
      end
    end
  elseif('del' == commandtype) then
    printenv()
    local sname = arg[2]

    if(nil == sname) then
      print('ERR:no systemname specify.')
      print(usage)
      return
    end
    print('delete system '..sname)

    local answer
    repeat
      io.write("("..sname..") all container and data will be delete,are you sure to do that.(y/n)? ")
      io.flush()
      answer=io.read()
    until answer=="y" or answer=="n"
    if(answer=="n") then
      return
    end

    delSystem(sname,config_his_base)
  elseif('start' == commandtype) then
    printenv()
    local sname = arg[2]
    if(nil == sname) then
      print('ERR:no systemname specify.')
      print(usage)
      return
    end
    local mname = arg[3]
    if(nil ~= mname) then
      print('start system:'..sname..' module:'..mname)
      startSystemModule(sname,mname,config_his_base)
    else
      print('start system:'..sname)
      startSystem(sname,config_his_base)
    end 
  elseif('restart' == commandtype) then
    printenv()
    local sname = arg[2]
    local mname = arg[3]
    if(nil == sname) then
      print('ERR:no systemname specify.')
      print(usage)
      return
    end
    if(nil == mname) then
      print('restart system '..sname)
      restartSystem(sname,config_his_base)
    else
      print('restart system '..sname..' :'..mname)
      restartSystemModule(sname,config_his_base,mname)
    end
  elseif('stop' == commandtype) then
    printenv()
    local sname = arg[2]
    if(nil == sname) then
      print('ERR:no systemname specify.')
      print(usage)
      return
    end
    local mname = arg[3]
    if(nil ~= mname) then
      print('stop system:'..sname..' module:'..mname)
      stopSystemModule(sname,mname,config_his_base)
    else
      print('stop system '..sname)
      stopSystem(sname,config_his_base)
    end
    
  elseif('help' == commandtype) then
    printenv()
    print(usage)
  elseif('update' == commandtype) then
    printenv()
    local configfile = arg[2]
    if(nil == configfile) then
      print('no specify configfile will find default(xftdconfig.xml) in '..xftd_root)
      return
    end

    updateSystem(configfile, xftd_root, config_his_base, config_release_base)
  elseif('updatem' == commandtype) then
    printenv()
    local configfile = arg[2]
    local modulenames = arg[3]
    if(nil == configfile) then
      print('no specify configfile will find default(xftdconfig.xml) in '..xftd_root)
      return
    else
      if(nil == modulenames) then
        print('no modulenames specify.')
        return
      else
        updateModules(configfile,modulenames,config_his_base,config_release_base)
      end
    end      
  elseif('status' == commandtype) then
    printenv()
    local sname = arg[2]
    if(nil == sname) then
      print('ERR:no systemname specify.')
      print(usage)
      return
    end    
    showsstatus(sname,config_his_base)
  elseif('initdb' == commandtype) then
    printenv()
    local configfile = arg[2]

    if(nil == configfile) then
      print('no specify configfile will find default(xftdconfig.xml) in '..xftd_root)
      return
    end 

    --[sourcedb:database1,database2...] [targetdb] [nocs]
    local sdbc = arg[3]
    local tdb = arg[4]
    local nocs = arg[5]
    if(nil == sdbc or nil == tdb) then
      print('ERR:no sourcedb or targetdb specify.')
      print(usage)
      return      
    end

    local cst = sdbc:split(':')
    --print(cst[1])
    --print(cst[2])
    local dbs = cst[2]:split(',')
    --print(dbs[1],dbs[2],dbs[3])
    local nocsb = false
    if(nil ~= nocs and 'nocs' == nocs) then
      nocsb = true
    end
    initdb(configfile,mysqlclient_base,tmp_base,cst[1],dbs,tdb,nocsb)
  elseif('initdbuser' == commandtype) then
    printenv()
    local configfile = arg[2]

    if(nil == configfile) then
      print('no specify configfile will find default(xftdconfig.xml) in '..xftd_root)
      return
    end 

    local tdb = arg[3]
    if(nil == tdb) then
      print('ERR:no targetdb specify.')
      print(usage)
      return      
    end
    initdbuser(configfile,xftd_root,mysqlclient_base,tdb)
  elseif('reconfig' == commandtype) then
    printenv()
    local configfile = arg[2]

    if(nil == configfile) then
      print('no specify configfile')
      return
    end 

    reconfig(configfile,config_his_base)    
  elseif('ol' == commandtype) then
    print('to online opt.')
    
    --#新版本发布上线
    --ol r systemname modulename
    
    --#重启/停止/启动
    --2ol s/st/rs/sts systemname modulename
    
    --#回滚上一版本/指定版本
    --2ol rb systemname modulename releaseversion

    local configfile = arg[2]
    local cmd2 = arg[3]
    if(nil == cmd2) then
      print('ERR:cmd is null.')
      return
    end
    local olmname = arg[4]
    if(nil == olmname) then
      print('ERR:module name is null.')
      return
    end    

    if('r' == cmd2) then
      releaseol(configfile, olmname, config_release_base)
    elseif('rb' == cmd2) then
      local olversion = arg[5]
      if(nil == olversion) then
        print('ERR:version is null.')
        return
      end
      rollbackol(configfile, olmname, olversion)
    elseif('s' == cmd2) then
      startol(configfile, olmname)
    elseif('st' == cmd2) then
      stopol(configfile, olmname)
    elseif('rs' == cmd2) then
      restartol(configfile, olmname)
    elseif('sts' == cmd2) then
      showstatusol(configfile, olmname)
    else 
      print('ERR:unsupport command:'..cmd2)
    end

  else
    print('ERR:unsupport command:'..commandtype)
    print(usage)
  end  
end

main()
