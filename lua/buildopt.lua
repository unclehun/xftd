--[[
  clarkewanglei@gmail.com
--]]
require("lfs")
require("fileopt")

require("commonutils")
require("list")

function build(modulename,buildcmd, buildcmdpd, mvnpath, gradlepath, javabase,nodepath, srcpath,releasebase,buildprod,tmpbase)  
  local bct = string.lower(buildcmd[1])
  if(startswith(bct,'mvn')) then
    return buildmvn(modulename,mvnpath, srcpath, javabase, buildcmd, buildcmdpd,releasebase,buildprod,tmpbase)
  elseif(startswith(bct,'gradle')) then
    return buildgradle(modulename,gradlepath, srcpath, javabase, buildcmd, buildcmdpd,releasebase,buildprod,tmpbase)
  elseif(startswith(bct,'yarn')) then
    return buildvue(modulename,nodepath, srcpath, buildcmd, buildcmdpd,releasebase,buildprod)
  else
    print('unsupport build cmd', buildcmd)
    return nil
  end
end

function buildmvn(modulename, mvnpath, srcpath, javabase, buildcmd, buildcmdpd,releasebase,buildprod,tmpbase)
  local dpc = 'echo $PATH'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)

  local setjavapath = string.contains(a,javabase)

  dpc = mvnpath..'/mvn --version'
  print(dpc)
  t= io.popen(dpc)
  a = t:read("*all")
  print(a)

  --##测试包
  local targetloc = ''
  for i,k in pairs(buildcmd) do
    print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
    print('build module ['..modulename..']')
    print('srcpath ['..srcpath..']')
    print('buildcmd ['..k..']')
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
    
    if(not string.contains(k,'ejarloc')) then
    --if(true ~= string.contains(k,'ejarloc')) then
      --执行编译命令
      dpc = mvnpath..'/'..string.gsub(k,"$srcpath",srcpath)..''
      dpc = string.gsub(dpc, "$setting", string.gsub(mvnpath, "bin", "conf/settings.xml"))
      if(not setjavapath) then   
      --if(true ~= setjavapath) then
        dpc = 'export PATH=$PATH:'..javabase..'&&'..dpc
      end
      print("dpc:",dpc)
      t= io.popen(dpc)
      a = t:read("*all")
      print(a)     
    else
      -- 解析execute jar包所在目录位置
      local tat = k:split(' ')
      if('.' ~= tat[2]) then
        targetloc = tat[2]
      end
      print('ejarloc:',tat[2])
    end
  end
  
  --编译所在目录
  local releasepath = srcpath..'/'..targetloc..'/target/'
  local rplen = 0
  local rp = nil

  --删除无关干扰文件
  dpc = 'rm -rf '..releasepath..'/*.gz&&rm -rf '..releasepath..'/*.tar'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  --从编译目录寻找尺寸最大的.jar文件
  for file in lfs.dir(releasepath) do
    rpl = length_of_file(releasepath..file)
    print(file, rpl)
    if('.'~=file and '..'~=file and rplen < rpl and endswith(file,'.jar')) then
      rp = file..''
      rplen = rpl
    end
  end
  
  --如果配置为不编译线上包,则直接返回
  print('buildprod=',buildprod)
  if(not buildprod) then
  --if(true ~= buildprod) then
    print('no build prod package')
    return {rp,releasepath}
  end

  --jar包改名为.test文件以区分后面打出的线上包.prod
  local rpcn = rp..'.test'
  print('rename '..releasepath..rp..'----> '..releasepath..rpcn)
  print('rename rslt:', os.rename(releasepath..rp, releasepath..rpcn))
  
  --##线上包
  local ssame = false
  for i,k in pairs(buildcmdpd) do
    print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
    print('build module ['..modulename..']')
    print('srcpath ['..srcpath..']')
    print('buildcmdpd ['..k..']')
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
    
    if(string.contains(k,'ejarloc')) then
    --if(true == string.contains(k,'ejarloc')) then
      goto continue
    end
    
    if('SAME' ~= k) then
      --移动测试包到临时目录躲避clean
      dpc = 'mv '..releasepath..'/'..rpcn..' '..tmpbase..'/'..rpcn
      t = io.popen(dpc)
      print(dpc)
      a = t:read("*all")
      print(a)
  
      --执行线上包编译命令
      dpc = mvnpath..'/'..string.gsub(k,"$srcpath",srcpath)..''
      dpc = string.gsub(dpc, "$setting", string.gsub(mvnpath, "bin", "conf/settings.xml"))
      if(not setjavapath) then
      --if(false == setjavapath) then
        dpc = 'export PATH=$PATH:'..javabase..'&&'..dpc
      end
      print("dpc:",dpc)
      t = io.popen(dpc)
      a = t:read("*all")
      print(a)
      
      --将测试包从临时目录移动回来
      dpc = 'mv '..tmpbase..'/'..rpcn..' '..releasepath..'/'..rpcn
      t = io.popen(dpc)
      print(dpc)
      a = t:read("*all")
      print(a)
    else
      --如果配置为SAME,则线上包和测试包使用相同编译命令,不再编译,将测试包copy到线上包目录
      ssame = true
      print('build cmd prod same with test.')
    end
    
    ::continue::
  end
  
  local rppdcn = releasepath..rp..'.prod'
  print('type of ssame:', type(ssame), ssame)
  if(ssame) then
  --if(true == ssame) then
    --如果配置为SAME,则线上包和测试包使用相同编译命令,不再编译,将测试包copy的线上包目录
    dpc = 'cp -r '..releasepath..'/'..rpcn..' '..rppdcn
    t = io.popen(dpc)
    print(dpc)
    a = t:read("*all")
    print(a)
  else
    --删除无关干扰文件
    dpc = 'rm -rf '..releasepath..'/*.gz&&rm -rf '..releasepath..'/*.tar'
    t = io.popen(dpc)
    print(dpc)
    a = t:read("*all")
    print(a)
    
    --从编译文件中寻找尺寸最大的.jar文件
    local rplenpd = 0
    local rppd = nil
    for file in lfs.dir(releasepath) do
      rpl = length_of_file(releasepath..file)
      print(file, rpl)
      if('.'~=file and '..'~=file and rplenpd < rpl and endswith(file,'.jar')) then
        rppd = file..''
        rplenpd = rpl
      end
    end

    --编译结果包改名为线上包.prod
    print('rename '..releasepath..rppd..'----> '..rppdcn)
    print('rename rslt', os.rename(releasepath..rppd, rppdcn))
  end
  
  --清理和生成线上包存储目录
  local mrlspath = releasebase..'/'..modulename..'/'
  dpc = 'rm -rf '..mrlspath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'mkdir -p '..mrlspath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  --copy .prod包到线上包存储目录
  print('rppdcn',rppdcn)
  local smt = string.match(rppdcn, ".+/([^/]*%.%w+)$")
  print('smt',smt)
  local smtt = string.gsub(smt,"%.prod","")
  dpc = 'cp -r '..rppdcn..' '..mrlspath..smtt
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

  -- centos 安装shasum  yum install perl-Digest-SHA
  dpc = 'shasum -a 256 '..mrlspath..smtt..'>'..mrlspath..'fp.txt'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)  

  return {rpcn,releasepath}
end

function buildgradle(modulename,gradlepath, srcpath, javabase, buildcmd, buildcmdpd, releasebase,buildprod,tmpbase)
  local dpc = 'echo $PATH'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)

  local setjavapath = string.contains(a,javabase)

  dpc = gradlepath..'/gradle --version'
  print(dpc)
  t= io.popen(dpc)
  a = t:read("*all")
  print(a)

  --##测试包
  local targetloc = ''
  for i,k in pairs(buildcmd) do
    print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
    print('build module ['..modulename..']')
    print('srcpath ['..srcpath..']')
    print('buildcmd ['..k..']')
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
    
    if(not string.contains(k,'ejarloc')) then
    --if(true ~= string.contains(k,'ejarloc')) then
      dpc = gradlepath..'/'..string.gsub(k,"$srcpath",srcpath)..''
      if(not setjavapath) then
      --if(false == setjavapath) then
        dpc = 'export PATH=$PATH:'..javabase..'&&'..dpc
      end     
      print("dpc:",dpc)
      t= io.popen(dpc)
      a = t:read("*all")
      print(a)
    else
      -- 解析execute jar包所在目录位置
      local tat = k:split(' ')
      if('.' ~= tat[2]) then
        targetloc = tat[2]
      end
      print('ejarloc:',tat[2])
    end
  end
  
  local releasepath = srcpath..'/'..targetloc..'/build/libs/'
  --local releasepath = srcpath..'/build/libs/'
  local rplen = 0
  local rp = nil
  for file in lfs.dir(releasepath) do
    rpl = length_of_file(releasepath..file)
    print(file, rpl)
    if('.'~=file and '..'~=file and rplen < rpl and endswith(file,'.jar')) then
      rp = file..''
      rplen = rpl
    end
  end
  
  print('buildprod=',type(buildprod),buildprod)
  if(not buildprod) then
  --if(true ~= buildprod) then
    print('no build prod package')
    return {rp,releasepath}
  end
  
  local rpcn = rp..'.test'
  print('rename '..releasepath..rp..'----> '..releasepath..rpcn)
  print('rename rslt:', os.rename(releasepath..rp, releasepath..rpcn))

  --##线上包
  local ssame = false
  for i,k in pairs(buildcmdpd) do
    print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
    print('build module ['..modulename..']')
    print('srcpath ['..srcpath..']')
    print('buildcmdpd ['..k..']')
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
    
    if(string.contains(k,'ejarloc')) then
    --if(true == string.contains(k,'ejarloc')) then
      print('goto continue.')
      goto continue
    end    

    if('SAME' ~= k) then
      print('product build cmd not same with test.')
      --移动测试包到临时目录躲避clean
      dpc = 'mv '..releasepath..'/'..rpcn..' '..tmpbase..'/'..rpcn
      t = io.popen(dpc)
      print(dpc)
      a = t:read("*all")
      print(a)

      dpc = gradlepath..'/'..string.gsub(k,"$srcpath",srcpath)..''
      if(not setjavapath) then
      --if(false == setjavapath) then
        dpc = 'export PATH=$PATH:'..javabase..'&&'..dpc
      end     
      print("dpc:",dpc)
      t = io.popen(dpc)
      a = t:read("*all")
      print(a)
      
      --将测试包从临时目录移动回来
      dpc = 'mv '..tmpbase..'/'..rpcn..' '..releasepath..'/'..rpcn
      t = io.popen(dpc)
      print(dpc)
      a = t:read("*all")
      print(a)
    else
      print('build cmd prod same with test.')
      ssame = true
    end
    
    ::continue::
  end 
  
  local rppdcn = releasepath..rp..'.prod'
  print('type of ssame:', type(ssame), ssame)
  if(ssame) then 
  --if(true == ssame) then 
    print('################same with test.#####################')
    dpc = 'cp -r '..releasepath..'/'..rpcn..' '..rppdcn
    t = io.popen(dpc)
    print(dpc)
    a = t:read("*all")
    print(a)
  else
    local rplenpd = 0
    local rppd = nil
    for file in lfs.dir(releasepath) do
      rpl = length_of_file(releasepath..file)
      print(file, rpl)
      if('.'~=file and '..'~=file and rplenpd < rpl and endswith(file,'.jar')) then
        rppd = file..''
        rplenpd = rpl
      end
    end

    print('rename '..releasepath..rppd..'----> '..rppdcn)
    print('rename result', os.rename(releasepath..rppd, rppdcn))
    
  end
  
  local mrlspath = releasebase..'/'..modulename..'/'
  dpc = 'rm -rf '..mrlspath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'mkdir -p '..mrlspath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

  print('rppdcn',rppdcn)
  local smt = string.match(rppdcn, ".+/([^/]*%.%w+)$")
  print('smt',smt)
  local smtt = string.gsub(smt,"%.prod","")
  dpc = 'cp -r '..rppdcn..' '..mrlspath..smtt
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  --centos 安装shasum  yum install perl-Digest-SHA
  dpc = 'shasum -a 256 '..mrlspath..smtt..'>'..mrlspath..'fp.txt'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)   

  print('build gradle: rp->'..rpcn..'  releasepath->'..releasepath)
  return {rpcn,releasepath}
end

function buildvue(modulename,nodepath, srcpath, buildcmd, buildcmdpd, releasebase,buildprod)
  local dpc = 'echo $PATH'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)

  local setnodepath = string.contains(a,nodepath)

  dpc = nodepath..'/node -v'
  print(dpc)
  t= io.popen(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'cd '..nodepath..'&&vue -V'
  print(dpc)
  t = io.popen(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'cd '..nodepath..'&&yarn -v'
  print(dpc)
  t= io.popen(dpc)
  a = t:read("*all")
  print(a)
  
  --##测试包
  for i,k in pairs(buildcmd) do
    print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
    print('build module ['..modulename..']')
    print('srcpath ['..srcpath..']')
    print('buildcmd ['..k..']')
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')  
    dpc = nodepath..'/'..string.gsub(k,"$srcpath",srcpath)..''
    local setregistry = nodepath..'/yarn config set registry https://registry.npm.taobao.org'
    dpc = setregistry..'&&'..dpc
    if(not setnodepath) then
    --if(false == setnodepath) then
      dpc = 'export PATH=$PATH:'..nodepath..'&&'..dpc
    end

    print("dpc:",dpc)
    t= io.popen(dpc)
    a = t:read("*all")
    print(a)
  end

  local rp = srcpath..'/dist'
  
  print('buildprod=',buildprod)
  if(not buildprod) then
  --if(true ~= buildprod) then
    print('no build prod package,buildvue return rp:',rp)
    return {nil,rp}
  end

  local rpcn = rp..'.test'
  dpc = 'mv '..rp..' '..rpcn
  print(dpc)
  t = io.popen(dpc)
  a = t:read("*all")
  print(a)
  
  --##线上包
  local ssame = false
  for i,k in pairs(buildcmdpd) do
    print('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@')
    print('build module ['..modulename..']')
    print('srcpath ['..srcpath..']')
    print('buildcmdpd ['..k..']')
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n')
    if('SAME' ~= k) then
      dpc = nodepath..'/'..string.gsub(k,"$srcpath",srcpath)..''
      local setregistry = nodepath..'/yarn config set registry https://registry.npm.taobao.org'
      dpc = setregistry..'&&'..dpc
      if(not setnodepath) then
      --if(false == setnodepath) then
        dpc = 'export PATH=$PATH:'..nodepath..'&&'..dpc
      end

      print("dpc:",dpc)
      t= io.popen(dpc)
      a = t:read("*all")
      print(a)    
    else
      ssame = true
      print('build cmd prod same with test.')      
    end
  end

  local rppd = srcpath..'/dist'
  local rppdcn = rppd..'.prod'
  print('type of ssame:', type(ssame), ssame)
  if(ssame) then
  --if(true == ssame) then
    dpc = 'cp -r '..rpcn..' '..rppdcn
    t = io.popen(dpc)
    print(dpc)
    a = t:read("*all")
    print(a)    
  else
    dpc = 'mv '..rppd..' '..rppdcn
    print(dpc)
    t = io.popen(dpc)
    a = t:read("*all")
    print(a)    
  end
  
  local mrlspath = releasebase..'/'..modulename..'/'
  dpc = 'rm -rf '..mrlspath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'mkdir -p '..mrlspath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'cp -r '..rppdcn..' '..mrlspath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'mv '..mrlspath..'/dist.prod'..' '..mrlspath..'/dist'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  --tar -czvf dist.tar.gz dist/
  --dpc = 'tar -czvf '..mrlspath..'dist.tar.gz'..' '..mrlspath..'dist'
  dpc = 'cd '..mrlspath..'&&tar -czvf dist.tar.gz dist'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

  dpc = 'shasum -a 256 '..mrlspath..'dist.tar.gz'..'>'..mrlspath..'fp.txt'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

  dpc = 'rm -rf '..mrlspath..'/dist'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

  print('buildvue return rpcn:',rpcn)
  return {nil,rpcn}
end