#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/opt:/root/.nvm/versions/node/v8.11.1/bin
export PATH

#Author:zsnmwy
#version:1.0
#Github:https://github.com/zsnmwy/Caddy-FileManage-WebDav


source /etc/os-release
VERSION=$(echo ${VERSION} | awk -F "[()]" '{print $2}')


####Color TIPS#######
Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"

Info=${Info_font_prefix}[信息]${Font_suffix}
Succeed=${Info_font_prefix}[成功]${Font_suffix}
Error=${Error_font_prefix}[错误]${Font_suffix}


Green="\033[32m"
Red="\033[31m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

file_path="/opt/caddy"
filemanager_database_path="/opt/caddy"

judge(){
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}

domain_check(){
    domain_ip=`ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    echo -e "${OK} ${GreenBG} 正在获取 公网ip 信息，请耐心等待 ${Font}"
    local_ip=`curl -4 ip.sb`
    echo -e "${OK} ${GreenBG} 域名dns解析IP：${domain_ip} ${Font}"
    echo -e "${OK} ${GreenBG} 本机IP: ${local_ip} ${Font}"
    sleep 2
    if [[ $(echo ${local_ip}|tr '.' '+'|bc) -eq $(echo ${domain_ip}|tr '.' '+'|bc) ]];then
        echo -e "${OK} ${GreenBG} 域名dns解析IP  与 本机IP 匹配 域名解析正确 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP不一致，会造成Caddy在证书自动申请的时候失败"
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP不一致，会造成Caddy在证书自动申请的时候失败"
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP不一致，会造成Caddy在证书自动申请的时候失败"
        echo -e "\n\n"
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP 不匹配 是否继续安装？（y/n）${Font}" && read install
        case $install in
            [yY][eE][sS]|[yY])
                echo -e "${GreenBG} 继续安装 ${Font}"
                sleep 2
            ;;
            *)
                echo -e "${RedBG} 安装终止 ${Font}"
                exit 2
            ;;
        esac
    fi
}

Get_Information(){
    echo -e "${Info} ${GreenBG} 请输入你的域名信息(如:bing.com 不要前面的www.)，请确保域名A记录已正确解析至服务器IP ${Font}"
    stty erase '^H' && read -p "请输入：" domain
    domain_check
    echo -e "${Info} ${GreenBG} 请输入邮箱，用于申请ssl证书 ${Font}"
    stty erase '^H' && read -p "请输入：" email
    echo -e "${Info} ${GreenBG} 请输入 WebDav的用户名。\n PS:当你使用webdav服务连接时，请输入该用户名 ${Font}"
    stty erase '^H' && read -p "请输入：" webdav_account
    echo -e "${Info} ${GreenBG} 请输入 WebDav的密码。\n PS:当你使用webdav服务连接时，请输入该密码 ${Font}"
    stty erase '^H' && read -p "请输入：" webdav_password
    echo -e "${Info} ${GreenBG} 请输入 WebDav的挂载点。请输入绝对路径 例子： /home/ubuntu ${Font}"
    stty erase '^H' && read -p "请输入：" webdav_path
    echo -e "${Info} ${GreenBG} 请输入 FileManager的挂载点。请输入绝对路径 例子： /home/ubuntu ${Font}"
    stty erase '^H' && read -p "请输入：" filemanager_file_path
    echo -e "\n\n----------------------------------------------------------"
    echo -e "${Info} ${GreenBG} 你输入的配置信息为 ${Font}"
    echo -e "${Info} ${GreenBG} 域名：${domain} ${Font}"
    echo -e "${Info} ${GreenBG} email：${email} ${Font}"
    echo -e "${Info} ${GreenBG} WebDav用户名：${webdav_account} ${Font}"
    echo -e "${Info} ${GreenBG} WebDav密码：${webdav_password} ${Font}"
    echo -e "${Info} ${GreenBG} Webdav的管理目录：${webdav_path} ${Font}"
    echo -e "${Info} ${GreenBG} FileManager的管理目录：${filemanager_file_path} ${Font}"
    echo -e "----------------------------------------------------------"
    echo -e "\n\n信息不对按 Ctrl+C 终止"
    read -n1 -p "Press any key to continue..."
}

Install_Requires(){
    if [[ "${ID}" == "centos" ]];
    then
        INS="yum"
    else
        INS="apt-get"
    fi
    ${INS} update
    ${INS} install -y curl wget nano unzip bc
}


Install_Caddy(){
    if ! curl https://getcaddy.com | bash -s personal http.filemanager,http.webdav;
    then
        echo -e "${Error}  安装Caddy失败" && exit 1
    fi
}

Add_Caddyfile(){
    mkdir -p ${file_path}
    judge "创建 ${file_path} 目录"
    echo "
${domain} {
    timeouts none
    tls ${email}
    gzip
    filemanager / ${filemanager_file_path} {
    database ${filemanager_database_path}/filemanager.db
    }
}
webdav.${domain} {
    timeouts none
    tls ${email}
    gzip
    basicauth / ${webdav_account} ${webdav_password}
    webdav {
    scope ${webdav_path}
    }
}
    " > ${file_path}/Caddyfile
    judge "写入Caddy的配置文件"
}

Install_nvm_node_V8.11.1_PM2() {
    ${INS} update
    ${INS} install wget -y
    echo -e "${Info} ${GreenBG} nvm安装阶段 ${Font}"
    wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash #This install
    judge "安装nvm"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
    echo -e "${Info} ${GreenBG} node安装阶段 ${Font}"
    nvm install 8.11.1 # This install node v8.11.1
    judge "安装node v8.11.1"
    node -v            # Show node version
    echo -e "${Info} ${GreenBG} pm2安装阶段 ${Font}"
    npm i -g pm2 # This install pm2
    judge "安装pm2"
}

Add_pm2_caddy_manage(){
    echo "
#!/usr/bin/env bash
cd ${file_path}
caddy
    " > ${file_path}/caddy.sh
    judge "添加caddy启动脚本"
}

caddy_pm2_start(){
    pm2 start ${file_path}/caddy.sh
    pm2 log caddy
}

caddy_pm2_restart(){
    pm2 restart caddy
    pm2 log caddy
}

caddy_pm2_delete(){
    pm2 delete caddy
}

Add_Toyo_aria2_install(){
    cd ${file_path}
    wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/aria2.sh && chmod +x aria2.sh
    judge "获取Toyo的 aria2 脚本"
}

Install_rclone(){
    curl https://rclone.org/install.sh | bash
    judge "安装rclone"
}

rinetdbbr_install(){
    export RINET_URL="https://github.com/dylanbai8/V2Ray_ws-tls_Website_onekey/raw/master/bbr/rinetd_bbr_powered"
    IFACE=$(ip -4 addr | awk '{if ($1 ~ /inet/ && $NF ~ /^[ve]/) {a=$NF}} END{print a}')
    
    curl -L "${RINET_URL}" >/usr/bin/rinetd-bbr
    chmod +x /usr/bin/rinetd-bbr
    judge "rinetd-bbr 安装"
    
    touch /etc/rinetd-bbr.conf
	cat <<EOF >> /etc/rinetd-bbr.conf
0.0.0.0 ${port} 0.0.0.0 ${port}
EOF
    
    touch /etc/systemd/system/rinetd-bbr.service
	cat <<EOF > /etc/systemd/system/rinetd-bbr.service
[Unit]
Description=rinetd with bbr
[Service]
ExecStart=/usr/bin/rinetd-bbr -f -c /etc/rinetd-bbr.conf raw ${IFACE}
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
    judge "rinetd-bbr 自启动配置"
    
    systemctl enable rinetd-bbr >/dev/null 2>&1
    systemctl start rinetd-bbr
    judge "rinetd-bbr 启动"
}

is_root(){
    if [ `id -u` == 0 ]
    then echo -e "${OK} ${GreenBG} 当前用户是root用户 ${Font}"
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}"
        exit 1
    fi
}

echo_message(){
    echo -e "\n\n"
    echo -e "${Info} ${GreenBG} WebDav 访问地址：https://webdav.${domain} ${Font}"
    echo -e "${Info} ${GreenBG} WebDav用户名：${webdav_account} ${Font}"
    echo -e "${Info} ${GreenBG} WebDav密码：${webdav_password} ${Font}"
    echo -e "${Info} ${GreenBG} Webdav的管理目录：${webdav_path} ${Font}"
    echo -e "\n\n"
    echo -e "${Info} ${GreenBG} FileManager 访问地址：https://${domain} ${Font}"
    echo -e "${Info} ${GreenBG} FileManager的管理目录：${filemanager_file_path} ${Font}"
    echo -e "${Info} ${GreenBG} FileManager的默认用户和密码都是 admin ${Font}"
}

General_Insatll(){
    is_root
    Install_Requires
    Get_Information
    Install_Caddy
    Add_Caddyfile
    Install_nvm_node_V8.11.1_PM2
    Add_pm2_caddy_manage
    rinetdbbr_install
    Add_Toyo_aria2_install
    ulimit -n 8192
    echo_message
}
is_root
echo "
Caddy + FileManage + webdav  一键脚本

Author zsnmwy

仅仅在Debian9 x64 上面进行测试
其他系统请自测

----------

请确保域名A记录已正确解析至服务器IP

Type    Name        Value
A       @           server ip
A       www         server ip
A       webdav      server ip

最后一个别忘了，webdav
到时候webdav的访问地址为 https://webdav.xxxxx.xxx

----------

1.安装
2.SSL证书自动申请有更改，请先选此选项。启动Caddy
############# PM2 ############
3.启动Caddy
4.查看Caddy日志
5.重启Caddy
6.删除Caddy
############# PM2 ############
7.Aria2 一键安装管理脚本 Toyo
8.安装rclone
9.退出
"
read -p "请输入数字:" VAR
case $VAR in
    1)
        General_Insatll
    ;;
    2)
        cd ${file_path}
        caddy
    ;;
    3)
        caddy_pm2_start
    ;;
    4)
        pm2 log caddy
    ;;
    5)
        caddy_pm2_restart
    ;;
    6)
        caddy_pm2_delete
    ;;
    7)
        bash ${file_path}/aria2.sh
    ;;
    8)
        Install_rclone
    ;;
    9)
        exit
    ;;
    *)
        echo "请输入数字"
        exit
    ;;
esac