--[[
  clarkewanglei@gmail.com
--]]

require("fileopt")
require("commonutils")

function buildimage(releasepath,releasefile,port,imagename,entrypointsh,telnetrpm)
  local centos7jdk8 = 'hljiangtao/centos7jdk8'
    
  local dpct = 'docker inspect --type=image '.. centos7jdk8
  local tt = io.popen(dpct)
  print(dpct)
  local at = tt:read("*all")
  print(at)
  --if(true == string.contains(at, 'No such image:') or true == string.contains(at, '[]')) then
  if(string.contains(at, 'No such image:') or string.contains(at, '[]')) then
    dpct = 'docker pull '.. centos7jdk8
    tt = io.popen(dpct)
    print(dpct)
    at = tt:read("*all")
    print(at)    
  else
    print('docker image:'..centos7jdk8..' have existed locally.')
  end
  
  local ct ='FROM '..centos7jdk8..'\n'
  --将本地文件夹挂载到当前容器，指定/tmp目录并持久化到Docker数据文件夹，因为Spring Boot使用的内嵌Tomcat容器默认使用/tmp作为工作目录
  ct =ct..'VOLUME /tmp\n'
  --添加自己的项目到 app.jar中   这里我是取了app.jar的名字，这个名字可以随便取的，只要后面几行名字和这个统一就好了
  print('add to image releasefile:',releasefile)
  ct =ct..'ADD '..releasefile..' /app.jar\n'
  --运行过程中创建一个app.jar文件
  --ct=ct.."RUN bash -c 'touch /app.jar'\n"
  
  --########centos---
  --ct=ct..'RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup\n'
  --ct=ct..'RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo\n' 
  --ct=ct..'RUN yum install -y telnet\n'  
  --本地安装telnet
  ct=ct..'ADD telnet-0.17-65.el7_8.x86_64.rpm /telnet-0.17-65.el7_8.x86_64.rpm\n'
  ct=ct..'RUN rpm --force -ivh /telnet-0.17-65.el7_8.x86_64.rpm\n'

  ct =ct..'COPY entrypoint.sh /usr/bin/\n'    
  --开放$port端口
  ct=ct..'EXPOSE '..port..'\n'
  --ENTRYPOINT指定容器运行后默认执行的命令
  --ct=ct..'ENTRYPOINT ["java","-jar","-Dspring.profiles.active=local","/app.jar"]'

  writefile(releasepath..'Dockerfile',ct)
  
  local dpc = 'rm -rf '..releasepath..'/entrypoint.sh&&cp '..entrypointsh..' '..releasepath..'entrypoint.sh&&chmod 777 '..releasepath..'/entrypoint.sh'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  
  dpc = 'rm -rf '..releasepath..'/telnet-0.17-65.el7_8.x86_64.rpm&&cp '..telnetrpm..' '..releasepath..'telnet-0.17-65.el7_8.x86_64.rpm&&chmod 777 '..releasepath..'/telnet-0.17-65.el7_8.x86_64.rpm'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)  

  --docker build $releasepath -t $imagename .
  dpc = 'docker build --no-cache -t '..imagename..' '..releasepath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

end


function buildimageft(releasepath,port,imagename,entrypointsh,nginxconf,telnetrpm)
  local centos7nginx = 'xiobe/centos7nginx-main'
  
  local dpct = 'docker inspect --type=image '.. centos7nginx
  local tt = io.popen(dpct)
  print(dpct)
  local at = tt:read("*all")
  print(at)
  --if(true == string.contains(at, 'No such image:') or true == string.contains(at, '[]')) then
  if(string.contains(at, 'No such image:') or string.contains(at, '[]')) then
    dpct = 'docker pull '.. centos7nginx
    tt = io.popen(dpct)
    print(dpct)
    at = tt:read("*all")
    print(at)    
  else
    print('docker image:'..centos7nginx..' have existed locally.')
  end

  local ct ='FROM '..centos7nginx..'\n'
  ct = ct..'EXPOSE '..port..'\n'
  ct = ct..'COPY entrypoint.sh /usr/bin/\n'

  ct = ct..'RUN rm -rf /etc/nginx/conf.d/default.conf\n'
  ct = ct..'COPY nginx_default_conf /etc/nginx/conf.d/default.conf\n'
  ct = ct..'COPY /dist /var/www/html\n'
 
  --#####centos-----
  --ct=ct..'RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup\n'
  --ct=ct..'RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo\n'
  --ct=ct..'RUN yum install -y telnet\n'
  --本地安装telnet
  ct=ct..'ADD telnet-0.17-65.el7_8.x86_64.rpm /telnet-0.17-65.el7_8.x86_64.rpm\n'
  ct=ct..'RUN rpm --force -ivh /telnet-0.17-65.el7_8.x86_64.rpm\n'    
  
  ct = ct..'ENTRYPOINT nginx -g "daemon off;"'

  writefile(releasepath..'Dockerfile',ct)
  
  local dpc = 'rm -rf '..releasepath..'/entrypoint.sh&&cp '..entrypointsh..' '..releasepath..'/entrypoint.sh&&chmod 777 '..releasepath..'/entrypoint.sh'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)  

  dpc = 'rm -rf '..releasepath..'/nginx_default_conf&&cp '..nginxconf..' '..releasepath..'nginx_default_conf&&chmod 777 '..releasepath..'/nginx_default_conf'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  dpc = 'rm -rf '..releasepath..'/telnet-0.17-65.el7_8.x86_64.rpm&&cp '..telnetrpm..' '..releasepath..'telnet-0.17-65.el7_8.x86_64.rpm&&chmod 777 '..releasepath..'/telnet-0.17-65.el7_8.x86_64.rpm'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)   

  dpc = 'docker build --no-cache -t '..imagename..' '..releasepath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

end

function buildimagemini(releasepath,releasefile,port,imagename,entrypointsh,telnet)
  local jdk = 'openjdk:11'
    
  local dpct = 'docker inspect --type=image '.. jdk
  local tt = io.popen(dpct)
  print(dpct)
  local at = tt:read("*all")
  --print(at)
  --if(true == string.contains(at, 'No such image:') or true == string.contains(at, '[]')) then
  if(string.contains(at, 'No such image:') or string.contains(at, '[]')) then
    dpct = 'docker pull '.. jdk
    tt = io.popen(dpct)
    print(dpct)
    at = tt:read("*all")
    print(at)    
  else
    print('docker image:'..jdk..' have existed locally.')
  end
  
  local ct ='FROM '..jdk..'\n'
  --将本地文件夹挂载到当前容器，指定/tmp目录并持久化到Docker数据文件夹，因为Spring Boot使用的内嵌Tomcat容器默认使用/tmp作为工作目录
  ct =ct..'VOLUME /tmp\n'
  --添加自己的项目到 app.jar中   这里我是取了app.jar的名字，这个名字可以随便取的，只要后面几行名字和这个统一就好了
  ct =ct..'ADD '..releasefile..' /app.jar\n'
  --运行过程中创建一个app.jar文件
  ct =ct.."RUN bash -c 'touch /app.jar'\n"
  ct =ct..'ENTRYPOINT ["java","-Dspring.profiles.active=docker", "-jar","/app.jar"]\n'
  --开放$port端口
  ct=ct..'EXPOSE '..port..'\n'

  --ct=ct..'RUN apt-get update\n'
  --ct=ct..'RUN apt-get install telnet -y\n'
  
  ct =ct..'COPY entrypoint.sh /usr/bin/\n' 
  --离线安装telnet
  ct=ct..'ADD telnet_0.17-42_amd64.deb /telnet_0.17-42_amd64.deb\n'
  ct=ct..'ADD netbase_6.3_all.deb /netbase_6.3_all.deb\n'
  
  ct=ct..'ADD xxd_8.2.2434-3_amd64.deb /xxd_8.2.2434-3_amd64.deb\n'
  ct=ct..'ADD vim-common_8.2.2434-3_all.deb /vim-common_8.2.2434-3_all.deb\n'
  ct=ct..'ADD libgpm2_1.20.7-8_amd64.deb /libgpm2_1.20.7-8_amd64.deb\n'
  ct=ct..'ADD vim-runtime_8.2.2434-3_all.deb /vim-runtime_8.2.2434-3_all.deb\n'
  ct=ct..'ADD vim_8.2.2434-3_amd64.deb /vim_8.2.2434-3_amd64.deb\n'
  ct=ct..'ADD libc6_2.31-13_amd64.deb /libc6_2.31-13_amd64.deb\n'
  ct=ct..'ADD libselinux1_3.1-3_amd64.deb /libselinux1_3.1-3_amd64.deb\n'
  ct=ct..'ADD libcrypt1_4.4.18-4_amd64.deb /libcrypt1_4.4.18-4_amd64.deb\n'
  ct=ct..'ADD libgcc-s1_10.2.1-6_amd64.deb /libgcc-s1_10.2.1-6_amd64.deb\n'  
  ct=ct..'ADD gcc-10-base_10.2.1-6_amd64.deb /gcc-10-base_10.2.1-6_amd64.deb\n' 
  
  
  ct=ct..'RUN dpkg -i netbase_6.3_all.deb\n'
  ct=ct..'RUN dpkg -i telnet_0.17-42_amd64.deb\n'
  
  ct=ct..'RUN dpkg -i xxd_8.2.2434-3_amd64.deb\n'
  ct=ct..'RUN dpkg -i vim-common_8.2.2434-3_all.deb\n'
  ct=ct..'RUN dpkg -i libgpm2_1.20.7-8_amd64.deb\n'
  ct=ct..'RUN dpkg -i vim-runtime_8.2.2434-3_all.deb\n'
  ct=ct..'RUN dpkg -i libcrypt1_4.4.18-4_amd64.deb\n'
  ct=ct..'RUN dpkg -i gcc-10-base_10.2.1-6_amd64.deb\n'
  ct=ct..'RUN dpkg -i libgcc-s1_10.2.1-6_amd64.deb\n'  
  ct=ct..'RUN dpkg -i libc6_2.31-13_amd64.deb\n'  
  ct=ct..'RUN dpkg -i libselinux1_3.1-3_amd64.deb\n' 
  ct=ct..'RUN dpkg -i vim_8.2.2434-3_amd64.deb\n'
  
  
  local dpc = 'rm -rf '..releasepath..'/entrypoint.sh&&cp '..entrypointsh..' '..releasepath..'/entrypoint.sh&&chmod 777 '..releasepath..'/entrypoint.sh'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)  

  dpc = 'rm -rf '..releasepath..'/telnet_0.17-42_amd64.deb&&cp '..telnet..' '..releasepath..'/telnet_0.17-42_amd64.deb&&chmod 777 '..releasepath..'/telnet_0.17-42_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

  local netbase = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','netbase_6.3_all.deb')

  dpc = 'rm -rf '..releasepath..'/netbase_6.3_all.deb&&cp '..netbase..' '..releasepath..'/netbase_6.3_all.deb&&chmod 777 '..releasepath..'/netbase_6.3_all.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  local xdd = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','xxd_8.2.2434-3_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/xxd_8.2.2434-3_amd64.deb&&cp '..xdd..' '..releasepath..'/xxd_8.2.2434-3_amd64.deb&&chmod 777 '..releasepath..'/xxd_8.2.2434-3_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
 
  local vimcommon = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','vim-common_8.2.2434-3_all.deb')

  dpc = 'rm -rf '..releasepath..'/vim-common_8.2.2434-3_all.deb&&cp '..vimcommon..' '..releasepath..'/vim-common_8.2.2434-3_all.deb&&chmod 777 '..releasepath..'/vim-common_8.2.2434-3_all.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
  
  local libgbpm2 = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libgpm2_1.20.7-8_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libgpm2_1.20.7-8_amd64.deb&&cp '..libgbpm2..' '..releasepath..'/libgpm2_1.20.7-8_amd64.deb&&chmod 777 '..releasepath..'/libgpm2_1.20.7-8_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
  
  local vimruntime = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','vim-runtime_8.2.2434-3_all.deb')

  dpc = 'rm -rf '..releasepath..'/vim-runtime_8.2.2434-3_all.deb&&cp '..vimruntime..' '..releasepath..'/vim-runtime_8.2.2434-3_all.deb&&chmod 777 '..releasepath..'/vim-runtime_8.2.2434-3_all.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
  
  local vim = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','vim_8.2.2434-3_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/vim_8.2.2434-3_amd64.deb&&cp '..vim..' '..releasepath..'/vim_8.2.2434-3_amd64.deb&&chmod 777 '..releasepath..'/vim_8.2.2434-3_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  local libc6 = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libc6_2.31-13_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libc6_2.31-13_amd64.deb&&cp '..libc6..' '..releasepath..'/libc6_2.31-13_amd64.deb&&chmod 777 '..releasepath..'/libc6_2.31-13_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
 
  local libselinux = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libselinux1_3.1-3_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libselinux1_3.1-3_amd64.deb&&cp '..libselinux..' '..releasepath..'/libselinux1_3.1-3_amd64.deb&&chmod 777 '..releasepath..'/libselinux1_3.1-3_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  local libcrypt = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libcrypt1_4.4.18-4_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libcrypt1_4.4.18-4_amd64.deb&&cp '..libcrypt..' '..releasepath..'/libcrypt1_4.4.18-4_amd64.deb&&chmod 777 '..releasepath..'/libcrypt1_4.4.18-4_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)  
 
  local libgcc_s1 = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libgcc-s1_10.2.1-6_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libgcc_s1_10.2.1-6_amd64.deb&&cp '..libgcc_s1..' '..releasepath..'/libgcc-s1_10.2.1-6_amd64.deb&&chmod 777 '..releasepath..'/libgcc-s1_10.2.1-6_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)      

  local gcc_10_base = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','gcc-10-base_10.2.1-6_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/gcc-10-base_10.2.1-6_amd64.deb&&cp '..gcc_10_base..' '..releasepath..'/gcc-10-base_10.2.1-6_amd64.deb&&chmod 777 '..releasepath..'/gcc-10-base_10.2.1-6_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)  

  writefile(releasepath..'Dockerfile',ct)

  --docker build $releasepath -t $imagename .
  dpc = 'docker build --no-cache -t '..imagename..' '..releasepath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

end


function buildimageftmini(releasepath,tdir,port,imagename,entrypointsh,nginxconf,telnet)
  local nginx = 'nginx:1.21.1'
  
  local dpct = 'docker inspect --type=image '.. nginx
  local tt = io.popen(dpct)
  print(dpct)
  local at = tt:read("*all")
  --print(at)
  --if(true == string.contains(at, 'No such image:') or true == string.contains(at, '[]')) then
  if(string.contains(at, 'No such image:') or string.contains(at, '[]')) then
    dpct = 'docker pull '.. nginx
    tt = io.popen(dpct)
    print(dpct)
    at = tt:read("*all")
    print(at)    
  else
    print('docker image:'..nginx..' have existed locally.')
  end

  local ct ='FROM '..nginx..'\n'
  ct = ct..'EXPOSE '..port..'\n'

  ct = ct..'RUN rm -rf /etc/nginx/conf.d/default.conf\n'
  ct = ct..'COPY nginx_config_router /etc/nginx/conf.d/default.conf\n'
  ct = ct..'COPY '..tdir..' /usr/share/nginx/html\n'
  --ct = ct..'ENTRYPOINT nginx -g "daemon off;"\n'
  
  ct =ct..'COPY entrypoint.sh /usr/bin/\n' 

  --离线安装telnet
  ct=ct..'ADD telnet_0.17-42_amd64.deb /telnet_0.17-42_amd64.deb\n'  
  ct=ct..'ADD netbase_6.3_all.deb /netbase_6.3_all.deb\n'
  
  ct=ct..'ADD xxd_8.2.2434-3_amd64.deb /xxd_8.2.2434-3_amd64.deb\n'
  ct=ct..'ADD vim-common_8.2.2434-3_all.deb /vim-common_8.2.2434-3_all.deb\n'
  ct=ct..'ADD libgpm2_1.20.7-8_amd64.deb /libgpm2_1.20.7-8_amd64.deb\n'
  ct=ct..'ADD vim-runtime_8.2.2434-3_all.deb /vim-runtime_8.2.2434-3_all.deb\n'
  ct=ct..'ADD vim_8.2.2434-3_amd64.deb /vim_8.2.2434-3_amd64.deb\n'
  ct=ct..'ADD libc6_2.31-13_amd64.deb /libc6_2.31-13_amd64.deb\n'
  ct=ct..'ADD libselinux1_3.1-3_amd64.deb /libselinux1_3.1-3_amd64.deb\n'
  ct=ct..'ADD libcrypt1_4.4.18-4_amd64.deb /libcrypt1_4.4.18-4_amd64.deb\n'
  ct=ct..'ADD libgcc-s1_10.2.1-6_amd64.deb /libgcc-s1_10.2.1-6_amd64.deb\n'  
  ct=ct..'ADD gcc-10-base_10.2.1-6_amd64.deb /gcc-10-base_10.2.1-6_amd64.deb\n'
  ct=ct..'ADD libpcre2-8-0_10.36-2_amd64.deb /libpcre2-8-0_10.36-2_amd64.deb\n'    
  
  
  ct=ct..'RUN dpkg -i netbase_6.3_all.deb\n'  
  ct=ct..'RUN dpkg -i telnet_0.17-42_amd64.deb\n'
  
  ct=ct..'RUN dpkg -i xxd_8.2.2434-3_amd64.deb\n'
  ct=ct..'RUN dpkg -i vim-common_8.2.2434-3_all.deb\n'
  ct=ct..'RUN dpkg -i libgpm2_1.20.7-8_amd64.deb\n'
  ct=ct..'RUN dpkg -i vim-runtime_8.2.2434-3_all.deb\n'
  ct=ct..'RUN dpkg -i libcrypt1_4.4.18-4_amd64.deb\n'
  ct=ct..'RUN dpkg -i gcc-10-base_10.2.1-6_amd64.deb\n'  
  ct=ct..'RUN dpkg -i libgcc-s1_10.2.1-6_amd64.deb\n'   
  ct=ct..'RUN dpkg -i libc6_2.31-13_amd64.deb\n'
  ct=ct..'RUN dpkg -i libpcre2-8-0_10.36-2_amd64.deb\n'
  ct=ct..'RUN dpkg -i libselinux1_3.1-3_amd64.deb\n'   
  ct=ct..'RUN dpkg -i vim_8.2.2434-3_amd64.deb\n'  

  local dpc = 'rm -rf '..releasepath..'/entrypoint.sh&&cp '..entrypointsh..' '..releasepath..'/entrypoint.sh&&chmod 777 '..releasepath..'/entrypoint.sh'
  local t = io.popen(dpc)
  print(dpc)
  local a = t:read("*all")
  print(a)
  
  dpc = 'rm -rf '..releasepath..'/nginx_config_router&&cp '..nginxconf..' '..releasepath..'/nginx_config_router&&chmod 777 '..releasepath..'/nginx_config_router'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)  

  dpc = 'rm -rf '..releasepath..'/telnet_0.17-42_amd64.deb&&cp '..telnet..' '..releasepath..'/telnet_0.17-42_amd64.deb&&chmod 777 '..releasepath..'/telnet_0.17-42_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 

  local netbase = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','netbase_6.3_all.deb')

  dpc = 'rm -rf '..releasepath..'/netbase_6.3_all.deb&&cp '..netbase..' '..releasepath..'/netbase_6.3_all.deb&&chmod 777 '..releasepath..'/netbase_6.3_all.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
  
  
  local xdd = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','xxd_8.2.2434-3_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/xxd_8.2.2434-3_amd64.deb&&cp '..xdd..' '..releasepath..'/xxd_8.2.2434-3_amd64.deb&&chmod 777 '..releasepath..'/xxd_8.2.2434-3_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
 
  local vimcommon = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','vim-common_8.2.2434-3_all.deb')

  dpc = 'rm -rf '..releasepath..'/vim-common_8.2.2434-3_all.deb&&cp '..vimcommon..' '..releasepath..'/vim-common_8.2.2434-3_all.deb&&chmod 777 '..releasepath..'/vim-common_8.2.2434-3_all.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
  
  local libgbpm2 = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libgpm2_1.20.7-8_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libgpm2_1.20.7-8_amd64.deb&&cp '..libgbpm2..' '..releasepath..'/libgpm2_1.20.7-8_amd64.deb&&chmod 777 '..releasepath..'/libgpm2_1.20.7-8_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
  
  local vimruntime = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','vim-runtime_8.2.2434-3_all.deb')

  dpc = 'rm -rf '..releasepath..'/vim-runtime_8.2.2434-3_all.deb&&cp '..vimruntime..' '..releasepath..'/vim-runtime_8.2.2434-3_all.deb&&chmod 777 '..releasepath..'/vim-runtime_8.2.2434-3_all.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 
  
  local vim = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','vim_8.2.2434-3_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/vim_8.2.2434-3_amd64.deb&&cp '..vim..' '..releasepath..'/vim_8.2.2434-3_amd64.deb&&chmod 777 '..releasepath..'/vim_8.2.2434-3_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)  
  
  local libc6 = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libc6_2.31-13_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libc6_2.31-13_amd64.deb&&cp '..libc6..' '..releasepath..'/libc6_2.31-13_amd64.deb&&chmod 777 '..releasepath..'/libc6_2.31-13_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
 
  local libselinux = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libselinux1_3.1-3_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libselinux1_3.1-3_amd64.deb&&cp '..libselinux..' '..releasepath..'/libselinux1_3.1-3_amd64.deb&&chmod 777 '..releasepath..'/libselinux1_3.1-3_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)    

  local libcrypt = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libcrypt1_4.4.18-4_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libcrypt1_4.4.18-4_amd64.deb&&cp '..libcrypt..' '..releasepath..'/libcrypt1_4.4.18-4_amd64.deb&&chmod 777 '..releasepath..'/libcrypt1_4.4.18-4_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)  
 
  local libgcc_s1 = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libgcc-s1_10.2.1-6_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libgcc-s1_10.2.1-6_amd64.deb&&cp '..libgcc_s1..' '..releasepath..'/libgcc-s1_10.2.1-6_amd64.deb&&chmod 777 '..releasepath..'/libgcc-s1_10.2.1-6_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)
  
  local gcc_10_base = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','gcc-10-base_10.2.1-6_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/gcc-10-base_10.2.1-6_amd64.deb&&cp '..gcc_10_base..' '..releasepath..'/gcc-10-base_10.2.1-6_amd64.deb&&chmod 777 '..releasepath..'/gcc-10-base_10.2.1-6_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)   

  local libpcre2 = string.gsub(telnet,'telnet_0%.17%-42_amd64%.deb','libpcre2-8-0_10.36-2_amd64.deb')

  dpc = 'rm -rf '..releasepath..'/libpcre2-8-0_10.36-2_amd64.deb&&cp '..libpcre2..' '..releasepath..'/libpcre2-8-0_10.36-2_amd64.deb&&chmod 777 '..releasepath..'/libpcre2-8-0_10.36-2_amd64.deb'
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a) 

  writefile(releasepath..'Dockerfile',ct)

  dpc = 'docker build --no-cache -t '..imagename..' '..releasepath
  t = io.popen(dpc)
  print(dpc)
  a = t:read("*all")
  print(a)

end