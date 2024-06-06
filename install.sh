#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if [ $(whoami) != "root" ]; then
    echo "Please use the [root] user to execute the aapanel installation script!"
    exit 1
fi

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
    Red_Error "Sorry, aaPanel does not support 32-bit systems"
fi

if [ -f "/etc/redhat-release" ]; then
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ]; then
        echo "Sorry, Centos6 does not support installing aaPanel"
        exit 1
    fi
fi

UbuntuCheck=$(cat /etc/issue | grep Ubuntu | awk '{print $2}' | cut -f 1 -d '.')
if [ "${UbuntuCheck}" -lt "16" ]; then
    echo "Ubuntu ${UbuntuCheck} is not supported to the aaPanel, it is recommended to replace the Ubuntu18/20 to install"
    exit 1
fi

HOSTNAME_CHECK=$(cat /etc/hostname)
if [ -z "${HOSTNAME_CHECK}" ];then
    echo "hostname is empty and the aaPanel cannot be installed. Please consult the server operator to set the hostname and then reinstall."
    exit 1
fi

cd ~
setup_path="/www"
python_bin=$setup_path/server/panel/pyenv/bin/python
cpu_cpunt=$(cat /proc/cpuinfo | grep processor | wc -l)
panelPort=$(expr $RANDOM % 55535 + 10000)
if [ "$1" ]; then
    IDC_CODE=$1
fi

Command_Exists() {
    command -v "$@" >/dev/null 2>&1
}

GetSysInfo() {
    if [ -s "/etc/redhat-release" ]; then
        SYS_VERSION=$(cat /etc/redhat-release)
    elif [ -s "/etc/issue" ]; then
        SYS_VERSION=$(cat /etc/issue)
    fi
    SYS_INFO=$(uname -a)
    SYS_BIT=$(getconf LONG_BIT)
    MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
    CPU_INFO=$(getconf _NPROCESSORS_ONLN)

    echo -e ${SYS_VERSION}
    echo -e Bit:${SYS_BIT} Mem:${MEM_TOTAL}M Core:${CPU_INFO}
    echo -e ${SYS_INFO}
    echo -e "Please screenshot the above error message and post to the forum forum.aapanel.com for help"
}
Red_Error() {
    echo '================================================='
    printf '\033[1;31;40m%b\033[0m\n' "$@"
    GetSysInfo
    exit 1
}
Lock_Clear() {
    if [ -f "/etc/bt_crack.pl" ]; then
        chattr -R -ia /www
        chattr -ia /etc/init.d/bt
        \cp -rpa /www/backup/panel/vhost/* /www/server/panel/vhost/
        mv /www/server/panel/BTPanel/__init__.bak /www/server/panel/BTPanel/__init__.py
        rm -f /etc/bt_crack.pl
    fi
}
Install_Check() {
    if [ "${INSTALL_FORCE}" ]; then
        return
    fi
    echo -e "----------------------------------------------------"
    echo -e "Web service is alreday installed,installing aaPanel may affect existing sites."
    echo -e "----------------------------------------------------"
    echo -e "Enter [yes] to force installation"
    read -p "Enter yes to force installation: " yes
    if [ "$yes" != "yes" ]; then
        echo -e "------------"
        echo "Installation canceled"
        exit
    fi
    INSTALL_FORCE="true"
}
System_Check() {
    MYSQLD_CHECK=$(ps -ef | grep mysqld | grep -v grep | grep -v /www/server/mysql)
    PHP_CHECK=$(ps -ef | grep php-fpm | grep master | grep -v /www/server/php)
    NGINX_CHECK=$(ps -ef | grep nginx | grep master | grep -v /www/server/nginx)
    HTTPD_CHECK=$(ps -ef | grep -E 'httpd|apache' | grep -v /www/server/apache | grep -v grep)
    if [ "${PHP_CHECK}" ] || [ "${MYSQLD_CHECK}" ] || [ "${NGINX_CHECK}" ] || [ "${HTTPD_CHECK}" ]; then
        Install_Check
    fi
}
Set_Ssl() {
    SET_SSL=true

    if [ "${SSL_PL}" ];then
    	SET_SSL=""
    fi
}

Get_Pack_Manager() {
    if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
        PM="yum"
    elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
        PM="apt-get"
    fi
}

Auto_Swap() {
    swap=$(free | grep Swap | awk '{print $2}')
    if [ "${swap}" -gt 1 ]; then
        echo "Swap total sizse: $swap"
        return
    fi
    if [ ! -d /www ]; then
        mkdir /www
    fi
    swapFile="/www/swap"
    dd if=/dev/zero of=$swapFile bs=1M count=1025
    mkswap -f $swapFile
    swapon $swapFile
    echo "$swapFile    swap    swap    defaults    0 0" >>/etc/fstab
    swap=$(free | grep Swap | awk '{print $2}')
    if [ $swap -gt 1 ]; then
        echo "Swap total sizse: $swap"
        return
    fi

    sed -i "/\/www\/swap/d" /etc/fstab
    rm -f $swapFile
}
Service_Add() {
    if Command_Exists systemctl ; then
        wget --no-check-certificate -O /usr/lib/systemd/system/btpanel.service ${download_Url}/init/systemd/btpanel.service -t 5 -T 15
        systemctl daemon-reload
        systemctl enable btpanel

    else
        if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
            chkconfig --add bt
            chkconfig --level 2345 bt on
        elif [ "${PM}" == "apt-get" ]; then
            update-rc.d bt defaults
        fi    
    fi
}

Set_Centos_Repo() {
    HUAWEI_CHECK=$(cat /etc/motd | grep "Huawei Cloud")
    if [ "${HUAWEI_CHECK}" ] && [ "${is64bit}" == "64" ]; then
        \cp -rpa /etc/yum.repos.d/ /etc/yumBak
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
        rm -f /etc/yum.repos.d/epel.repo
        rm -f /etc/yum.repos.d/epel-*
    fi
    ALIYUN_CHECK=$(cat /etc/motd | grep "Alibaba Cloud ")
    if [ "${ALIYUN_CHECK}" ] && [ "${is64bit}" == "64" ] && [ ! -f "/etc/yum.repos.d/Centos-vault-8.5.2111.repo" ]; then
        rename '.repo' '.repo.bak' /etc/yum.repos.d/*.repo
        wget https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo -O /etc/yum.repos.d/Centos-vault-8.5.2111.repo
        wget https://mirrors.aliyun.com/repo/epel-archive-8.repo -O /etc/yum.repos.d/epel-archive-8.repo
        sed -i 's/mirrors.cloud.aliyuncs.com/url_tmp/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo && sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo && sed -i 's/url_tmp/mirrors.aliyun.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo
        sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/epel-archive-8.repo
    fi
    MIRROR_CHECK=$(cat /etc/yum.repos.d/CentOS-Linux-AppStream.repo | grep "[^#]mirror.centos.org")
    if [ "${MIRROR_CHECK}" ] && [ "${is64bit}" == "64" ]; then
        \cp -rpa /etc/yum.repos.d/ /etc/yumBak
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
    fi
}

get_node_url() {
    if [ ! -f /bin/curl ]; then
        if [ "${PM}" = "yum" ]; then
            yum install curl -y
        elif [ "${PM}" = "apt-get" ]; then
            apt-get install curl -y
        fi
    fi

    if [ -f "/www/node.pl" ];then
        download_Url=$(cat /www/node.pl)
        echo "Download node: $download_Url";
        echo '---------------------------------------------';
        return
    fi
    
    echo '---------------------------------------------';
    echo "Selected download node...";
    nodes=(https://node.aapanel.com https://na1-node.bt.cn);

    if [ "$1" ];then
        nodes=($(echo ${nodes[*]}|sed "s#${1}##"))
    fi
    tmp_file1=/dev/shm/net_test1.pl
    tmp_file2=/dev/shm/net_test2.pl

    [ -f "${tmp_file1}" ] && rm -f ${tmp_file1}

    [ -f "${tmp_file2}" ] && rm -f ${tmp_file2}

    touch $tmp_file1
    touch $tmp_file2
    for node in ${nodes[@]}; do
        NODE_CHECK=$(curl -k --connect-timeout 3 -m 3 2>/dev/null -w "%{http_code} %{time_total}" ${node}/net_test|xargs)
        RES=$(echo ${NODE_CHECK} | awk '{print $1}')
        NODE_STATUS=$(echo ${NODE_CHECK} | awk '{print $2}')
        TIME_TOTAL=$(echo ${NODE_CHECK} | awk '{print $3 * 1000 - 500 }' | cut -d '.' -f 1)
        if [ "${NODE_STATUS}" == "200" ]; then
            if [ $TIME_TOTAL -lt 100 ]; then
                if [ $RES -ge 1500 ]; then
                    echo "$RES $node" >>$tmp_file1
                fi
            else
                if [ $RES -ge 1500 ]; then
                    echo "$TIME_TOTAL $node" >>$tmp_file2
                fi
            fi

            i=$(($i + 1))
            if [ $TIME_TOTAL -lt 100 ]; then
                if [ $RES -ge 3000 ]; then
                    break
                fi
            fi

        fi
    done

    NODE_URL=$(cat $tmp_file1 | sort -r -g -t " " -k 1 | head -n 1 | awk '{print $2}')
    if [ -z "$NODE_URL" ]; then
        NODE_URL=$(cat $tmp_file2 | sort -g -t " " -k 1 | head -n 1 | awk '{print $2}')
        if [ -z "$NODE_URL" ]; then
            NODE_URL='https://node.aapanel.com'
        fi
    fi

    rm -f $tmp_file1
    rm -f $tmp_file2
    download_Url=$NODE_URL
    echo "Download node: $download_Url"
    echo '---------------------------------------------'
}
Remove_Package() {
    local PackageNmae=$1
    if [ "${PM}" == "yum" ]; then
        isPackage=$(rpm -q ${PackageNmae} | grep "not installed")
        if [ -z "${isPackage}" ]; then
            yum remove ${PackageNmae} -y
        fi
    elif [ "${PM}" == "apt-get" ]; then
        isPackage=$(dpkg -l | grep ${PackageNmae})
        if [ "${PackageNmae}" ]; then
            apt-get remove ${PackageNmae} -y
        fi
    fi
}
Install_RPM_Pack() {
    yumPath=/etc/yum.conf
    Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
    if [ "${Centos8Check}" ]; then
        Set_Centos_Repo
    fi
    isExc=$(cat $yumPath | grep httpd)
    if [ "$isExc" = "" ]; then
        echo "exclude=httpd nginx php mysql mairadb python-psutil python2-psutil" >>$yumPath
    fi

    #yumBaseUrl=$(cat /etc/yum.repos.d/CentOS-Base.repo|grep baseurl=http|cut -d '=' -f 2|cut -d '$' -f 1|head -n 1)
    #[ "${yumBaseUrl}" ] && checkYumRepo=$(curl --connect-timeout 5 --head -s -o /dev/null -w %{http_code} ${yumBaseUrl})
    #if [ "${checkYumRepo}" != "200" ];then
    #	curl -Ss --connect-timeout 3 -m 60 http://node.aapanel.com/install/yumRepo_select.sh|bash
    #fi

    #尝试同步时间(从bt.cn)
    # 	echo 'Synchronizing system time...'
    # 	getBtTime=$(curl -sS --connect-timeout 3 -m 60 http://www.bt.cn/api/index/get_time)
    # 	if [ "${getBtTime}" ];then
    #     		date -s "$(date -d @$getBtTime +"%Y-%m-%d %H:%M:%S")"
    # 	fi

    #if [ -z "${Centos8Check}" ]; then
    #	yum install ntp -y
    #	rm -rf /etc/localtime
    #	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    #尝试同步国际时间(从ntp服务器)
    #	ntpdate 0.asia.pool.ntp.org
    #	setenforce 0
    #fi

    startTime=$(date +%s)

    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    #yum remove -y python-requests python3-requests python-greenlet python3-greenlet
    yumPacks="libcurl-devel wget tar gcc make zip unzip openssl openssl-devel gcc libxml2 libxml2-devel libxslt* zlib zlib-devel libjpeg-devel libpng-devel libwebp libwebp-devel freetype freetype-devel lsof pcre pcre-devel vixie-cron crontabs icu libicu-devel c-ares libffi-devel bzip2-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel firewalld ipset"
    yum install -y ${yumPacks}

    for yumPack in ${yumPacks}; do
        rpmPack=$(rpm -q ${yumPack})
        packCheck=$(echo ${rpmPack} | grep not)
        if [ "${packCheck}" ]; then
            yum install ${yumPack} -y
        fi
    done
    if [ -f "/usr/bin/dnf" ]; then
        dnf install -y redhat-rpm-config
    fi

    ALI_OS=$(cat /etc/redhat-release | grep "Alibaba Cloud Linux release 3")
    if [ -z "${ALI_OS}" ]; then
        yum install epel-release -y
    fi
}
Install_Deb_Pack() {
    ln -sf bash /bin/sh
    apt-get update -y
    apt-get install bash -y
    if [ -f "/usr/bin/bash" ];then
        ln -sf /usr/bin/bash /bin/sh
    fi
    apt-get install ruby -y
    apt-get install lsb-release -y
    #apt-get install ntp ntpdate -y
    #/etc/init.d/ntp stop
    #update-rc.d ntp remove
    #cat >>~/.profile<<EOF
    #TZ='Asia/Shanghai'; export TZ
    #EOF
    #rm -rf /etc/localtime
    #cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    #echo 'Synchronizing system time...'
    #ntpdate 0.asia.pool.ntp.org
    #apt-get upgrade -y
    LIBCURL_VER=$(dpkg -l | grep libcurl4 | awk '{print $3}')
    if [ "${LIBCURL_VER}" == "7.68.0-1ubuntu2.8" ]; then
        apt-get remove libcurl4 -y
        apt-get install curl -y
    fi

    debPacks="wget curl libcurl4-openssl-dev gcc make zip unzip tar openssl libssl-dev gcc libxml2 libxml2-dev zlib1g zlib1g-dev libjpeg-dev libpng-dev lsof libpcre3 libpcre3-dev cron net-tools swig build-essential libffi-dev libbz2-dev libncurses-dev libsqlite3-dev libreadline-dev tk-dev libgdbm-dev libdb-dev libdb++-dev libpcap-dev xz-utils git ufw ipset sqlite3"

    DEBIAN_FRONTEND=noninteractive apt-get install -y $debPacks --force-yes

    for debPack in ${debPacks}; do
        packCheck=$(dpkg -l ${debPack})
        if [ "$?" -ne "0" ]; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y $debPack
        fi
    done
    if [ ! -d '/etc/letsencrypt' ]; then
        mkdir -p /etc/letsencryp
        mkdir -p /var/spool/cron
        if [ ! -f '/var/spool/cron/crontabs/root' ]; then
            echo '' >/var/spool/cron/crontabs/root
            chmod 600 /var/spool/cron/crontabs/root
        fi
    fi
}
Get_Versions() {
    redhat_version_file="/etc/redhat-release"
    deb_version_file="/etc/issue"

    if [[ $(grep Anolis /etc/os-release) ]] && [[ $(grep VERSION /etc/os-release|grep 8.8) ]];then
        if [ -f "/usr/bin/yum" ];then
            os_type="anolis"
            os_version="8"
            return
        fi
    fi
    if [ -f $redhat_version_file ]; then
        os_type='el'
        is_aliyunos=$(cat $redhat_version_file | grep Aliyun)
        if [ "$is_aliyunos" != "" ]; then
            return
        fi

        if [[ $(grep "Alibaba Cloud" /etc/redhat-release) ]] && [[ $(grep al8 /etc/os-release) ]];then
            os_type="ali-linux-"
            os_version="al8"
            return
        fi

        if [[ $(grep "TencentOS Server" /etc/redhat-release|grep 3.1) ]];then
            os_type="TencentOS-"
            os_version="3.1"
            return
        fi

        os_version=$(cat $redhat_version_file | grep CentOS | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]')
        if [ "${os_version}" = "5" ]; then
            os_version=""
        fi
        if [ -z "${os_version}" ]; then
            os_version=$(cat /etc/redhat-release | grep Stream | grep -oE 8)
        fi
    else
        os_type='ubuntu'
        os_version=$(cat $deb_version_file | grep Ubuntu | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]+')
        if [ "${os_version}" = "" ]; then
            os_type='debian'
            os_version=$(cat $deb_version_file | grep Debian | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '[0-9]+')
            if [ "${os_version}" = "" ]; then
                os_version=$(cat $deb_version_file | grep Debian | grep -Eo '[0-9]+')
            fi
            if [ "${os_version}" = "8" ]; then
                os_version=""
            fi
            if [ "${is64bit}" = '32' ]; then
                os_version=""
            fi
        else
            if [ "$os_version" = "14" ]; then
                os_version=""
            fi
            if [ "$os_version" = "12" ]; then
                os_version=""
            fi
            if [ "$os_version" = "19" ]; then
                os_version=""
            fi
            if [ "$os_version" = "21" ]; then
                os_version=""
            fi
            if [ "$os_version" = "20" ]; then
                os_version2004=$(cat /etc/issue | grep 20.04)
                if [ -z "${os_version2004}" ]; then
                    os_version=""
                fi
            fi
        fi
    fi
}

Install_Python_Lib() {
    curl -Ss --connect-timeout 3 -m 60 https://github.com/mzwrt/aapanel-6.8.37-backup/blob/8c30a6d52db81e8067578b5fcf0c528677cdcc11/install/pip_select.sh | bash
    pyenv_path="/www/server/panel"
    if [ -f $pyenv_path/pyenv/bin/python ]; then
        is_ssl=$($python_bin -c "import ssl" 2>&1 | grep cannot)
        $pyenv_path/pyenv/bin/python3.7 -V
        if [ $? -eq 0 ] && [ -z "${is_ssl}" ]; then
            chmod -R 700 $pyenv_path/pyenv/bin
            is_package=$($python_bin -m psutil 2>&1 | grep package)
            if [ "$is_package" = "" ]; then
                wget --no-check-certificate -O $pyenv_path/pyenv/pip.txt https://github.com/mzwrt/aapanel-6.8.37-backup/blob/8c30a6d52db81e8067578b5fcf0c528677cdcc11/install/pip_en.txt -T 15
                $pyenv_path/pyenv/bin/pip install -U pip
                $pyenv_path/pyenv/bin/pip install -U setuptools
                $pyenv_path/pyenv/bin/pip install -r $pyenv_path/pyenv/pip.txt
            fi
            source $pyenv_path/pyenv/bin/activate
            chmod -R 700 $pyenv_path/pyenv/bin
            return
        else
            rm -rf $pyenv_path/pyenv
        fi
    fi

    is_loongarch64=$(uname -a | grep loongarch64)
    if [ "$is_loongarch64" != "" ] && [ -f "/usr/bin/yum" ]; then
        yumPacks="python3-devel python3-pip python3-psutil python3-gevent python3-pyOpenSSL python3-paramiko python3-flask python3-rsa python3-requests python3-six python3-websocket-client"
        yum install -y ${yumPacks}
        for yumPack in ${yumPacks}; do
            rpmPack=$(rpm -q ${yumPack})
            packCheck=$(echo ${rpmPack} | grep not)
            if [ "${packCheck}" ]; then
                yum install ${yumPack} -y
            fi
        done

        pip3 install -U pip
        pip3 install Pillow psutil pyinotify pycryptodome upyun oss2 pymysql qrcode qiniu redis pymongo Cython configparser cos-python-sdk-v5 supervisor gevent-websocket pyopenssl
        pip3 install flask==1.1.4
        pip3 install Pillow -U

        pyenv_bin=/www/server/panel/pyenv/bin
        mkdir -p $pyenv_bin
        ln -sf /usr/local/bin/pip3 $pyenv_bin/pip
        ln -sf /usr/local/bin/pip3 $pyenv_bin/pip3
        ln -sf /usr/local/bin/pip3 $pyenv_bin/pip3.7

        if [ -f "/usr/bin/python3.7" ]; then
            ln -sf /usr/bin/python3.7 $pyenv_bin/python
            ln -sf /usr/bin/python3.7 $pyenv_bin/python3
            ln -sf /usr/bin/python3.7 $pyenv_bin/python3.7
        elif [ -f "/usr/bin/python3.6" ]; then
            ln -sf /usr/bin/python3.6 $pyenv_bin/python
            ln -sf /usr/bin/python3.6 $pyenv_bin/python3
            ln -sf /usr/bin/python3.6 $pyenv_bin/python3.7
        fi

        echo >$pyenv_bin/activate

        return
    fi

    py_version="3.7.8"
    mkdir -p $pyenv_path
    echo "True" >/www/disk.pl
    if [ ! -w /www/disk.pl ]; then
        Red_Error "ERROR: Install python env fielded." "ERROR: path [www] cannot be written, please check the directory/user/disk permissions!"
    fi
    os_type='el'
    os_version='7'
    is_export_openssl=0
    Get_Versions
    echo "OS: $os_type - $os_version"
    is_aarch64=$(uname -a | grep aarch64)
    if [ "$is_aarch64" != "" ]; then
        is64bit="aarch64"
    fi
    if [ -f "/www/server/panel/pymake.pl" ]; then
        os_version=""
        rm -f /www/server/panel/pymake.pl
    fi
    if [ "${os_version}" != "" ]; then
        pyenv_file="/www/pyenv.tar.gz"
        wget --no-check-certificate -O $pyenv_file $download_Url/install/pyenv/pyenv-${os_type}${os_version}-x${is64bit}.tar.gz -T 15
        if [ "$?" != "0" ];then
            get_node_url $download_Url
            wget --no-check-certificate -O $pyenv_file $download_Url/install/pyenv/pyenv-${os_type}${os_version}-x${is64bit}.tar.gz -T 15
        fi
        tmp_size=$(du -b $pyenv_file | awk '{print $1}')
        if [ $tmp_size -lt 703460 ]; then
            rm -f $pyenv_file
            echo "ERROR: Download python env fielded."
        else
            echo "Install python env..."
            tar zxvf $pyenv_file -C $pyenv_path/ >/dev/null
            chmod -R 700 $pyenv_path/pyenv/bin
            if [ ! -f $pyenv_path/pyenv/bin/python ]; then
                rm -f $pyenv_file
                Red_Error "ERROR: Install python env fielded. Please try to reinstall"
            fi
            $pyenv_path/pyenv/bin/python3.7 -V
            if [ $? -eq 0 ]; then
                rm -f $pyenv_file
                ln -sf $pyenv_path/pyenv/bin/pip3.7 /usr/bin/btpip
                ln -sf $pyenv_path/pyenv/bin/python3.7 /usr/bin/btpython
                source $pyenv_path/pyenv/bin/activate
                return
            else
                rm -f $pyenv_file
                rm -rf $pyenv_path/pyenv
            fi
        fi
    fi

    cd /www
    python_src='/www/python_src.tar.xz'
    python_src_path="/www/Python-${py_version}"
    wget --no-check-certificate -O $python_src $download_Url/src/Python-${py_version}.tar.xz -T 15
    tmp_size=$(du -b $python_src | awk '{print $1}')
    if [ $tmp_size -lt 10703460 ]; then
        rm -f $python_src
        Red_Error "ERROR: Download python source code fielded. Please try to reinstall"
    fi
    tar xvf $python_src
    rm -f $python_src
    cd $python_src_path
    ./configure --prefix=$pyenv_path/pyenv
    make -j$cpu_cpunt
    make install
    if [ ! -f $pyenv_path/pyenv/bin/python3.7 ]; then
        rm -rf $python_src_path
        Red_Error "ERROR: Make python env fielded. Please try to reinstall"
    fi
    cd ~
    rm -rf $python_src_path
    wget --no-check-certificate -O $pyenv_path/pyenv/bin/activate https://github.com/mzwrt/aapanel-6.8.37-backup/blob/1fb1e5f25c75ac51b1cb132dcf4b034caa490de7/install/activate.panel -T 15
    wget --no-check-certificate -O $pyenv_path/pyenv/pip.txt https://github.com/mzwrt/aapanel-6.8.37-backup/blob/69438e94c8eb16886c333293fb9aeac293434c41/install/pip-3.7.8.txt -T 15
    ln -sf $pyenv_path/pyenv/bin/pip3.7 $pyenv_path/pyenv/bin/pip
    ln -sf $pyenv_path/pyenv/bin/python3.7 $pyenv_path/pyenv/bin/python
    ln -sf $pyenv_path/pyenv/bin/pip3.7 /usr/bin/btpip
    ln -sf $pyenv_path/pyenv/bin/python3.7 /usr/bin/btpython
    chmod -R 700 $pyenv_path/pyenv/bin
    $pyenv_path/pyenv/bin/pip install -U pip
    $pyenv_path/pyenv/bin/pip install -U setuptools
    $pyenv_path/pyenv/bin/pip install -U wheel==0.34.2
    $pyenv_path/pyenv/bin/pip install -r $pyenv_path/pyenv/pip.txt

    source $pyenv_path/pyenv/bin/activate

    is_gevent=$($python_bin -m gevent 2>&1 | grep -oE package)
    is_psutil=$($python_bin -m psutil 2>&1 | grep -oE package)
    if [ "${is_gevent}" != "${is_psutil}" ]; then
        Red_Error "ERROR: psutil/gevent install failed!"
    fi
}

delete_useless_package() {
    /www/server/panel/pyenv/bin/pip uninstall aliyun-python-sdk-kms -y
    /www/server/panel/pyenv/bin/pip uninstall aliyun-python-sdk-core -y
    /www/server/panel/pyenv/bin/pip uninstall aliyun-python-sdk-core-v3 -y
    /www/server/panel/pyenv/bin/pip uninstall qiniu -y
    /www/server/panel/pyenv/bin/pip uninstall cos-python-sdk-v5 -y
}

Install_Bt() {
    if [ -f ${setup_path}/server/panel/data/port.pl ]; then
        panelPort=$(cat ${setup_path}/server/panel/data/port.pl)
    fi

	if [ "${PANEL_PORT}" ];then
		panelPort=$PANEL_PORT
	fi

    delete_useless_package
    
    mkdir -p ${setup_path}/server/panel/logs
    mkdir -p ${setup_path}/server/panel/vhost/apache
    mkdir -p ${setup_path}/server/panel/vhost/nginx
    mkdir -p ${setup_path}/server/panel/vhost/rewrite
    mkdir -p ${setup_path}/server/panel/install
    mkdir -p /www/server
    mkdir -p /www/wwwroot
    mkdir -p /www/wwwlogs
    mkdir -p /www/backup/database
    mkdir -p /www/backup/site

    if [ ! -d "/etc/init.d" ];then
        mkdir -p /etc/init.d
    fi

    if [ -f "/etc/init.d/bt" ]; then
        /etc/init.d/bt stop
        sleep 1
    fi

    wget --no-check-certificate -O panel.zip https://github.com/mzwrt/aapanel-6.8.37-backup/blob/1fb1e5f25c75ac51b1cb132dcf4b034caa490de7/install/panel6_en.zip -T 15
    wget --no-check-certificate -O /etc/init.d/bt https://github.com/mzwrt/aapanel-6.8.37-backup/blob/1fb1e5f25c75ac51b1cb132dcf4b034caa490de7/install/bt6_en.init -T 15
    wget --no-check-certificate -O /www/server/panel/install/public.sh https://github.com/mzwrt/aapanel-6.8.37-backup/blob/1fb1e5f25c75ac51b1cb132dcf4b034caa490de7/install/public.sh -T 15

    if [ -f "${setup_path}/server/panel/data/default.db" ]; then
        if [ -d "/${setup_path}/server/panel/old_data" ]; then
            rm -rf ${setup_path}/server/panel/old_data
        fi
        mkdir -p ${setup_path}/server/panel/old_data
        d_format=$(date +"%Y%m%d_%H%M%S")
        \cp -arf ${setup_path}/server/panel/data/default.db ${setup_path}/server/panel/data/default_backup_${d_format}.db
        mv -f ${setup_path}/server/panel/data/default.db ${setup_path}/server/panel/old_data/default.db
        mv -f ${setup_path}/server/panel/data/system.db ${setup_path}/server/panel/old_data/system.db
        mv -f ${setup_path}/server/panel/data/port.pl ${setup_path}/server/panel/old_data/port.pl
        mv -f ${setup_path}/server/panel/data/admin_path.pl ${setup_path}/server/panel/old_data/admin_path.pl
    fi

    if [ ! -f "/usr/bin/unzip" ]; then
        if [ "${PM}" = "yum" ]; then
            yum install unzip -y
        elif [ "${PM}" = "apt-get" ]; then
            apt-get update
            apt-get install unzip -y
        fi
    fi
    unzip -o panel.zip -d ${setup_path}/server/ >/dev/null

    if [ -d "${setup_path}/server/panel/old_data" ]; then
        mv -f ${setup_path}/server/panel/old_data/default.db ${setup_path}/server/panel/data/default.db
        mv -f ${setup_path}/server/panel/old_data/system.db ${setup_path}/server/panel/data/system.db
        mv -f ${setup_path}/server/panel/old_data/port.pl ${setup_path}/server/panel/data/port.pl
        mv -f ${setup_path}/server/panel/old_data/admin_path.pl ${setup_path}/server/panel/data/admin_path.pl
        if [ -d "/${setup_path}/server/panel/old_data" ]; then
            rm -rf ${setup_path}/server/panel/old_data
        fi
    fi

    if [ ! -f ${setup_path}/server/panel/tools.py ] || [ ! -f ${setup_path}/server/panel/BT-Panel ]; then
        ls -lh panel.zip
        Red_Error "ERROR: Failed to download, please try install again!"
    fi

    rm -f panel.zip
    rm -f ${setup_path}/server/panel/class/*.pyc
    rm -f ${setup_path}/server/panel/*.pyc

    chmod +x /etc/init.d/bt
    chmod -R 600 ${setup_path}/server/panel
    chmod -R +x ${setup_path}/server/panel/script
    ln -sf /etc/init.d/bt /usr/bin/bt
    echo "${panelPort}" >${setup_path}/server/panel/data/port.pl
    wget --no-check-certificate -O /etc/init.d/bt https://github.com/mzwrt/aapanel-6.8.37-backup/blob/1fb1e5f25c75ac51b1cb132dcf4b034caa490de7/install/bt6_en.init -T 15
    wget --no-check-certificate -O /www/server/panel/init.sh https://github.com/mzwrt/aapanel-6.8.37-backup/blob/1fb1e5f25c75ac51b1cb132dcf4b034caa490de7/install/bt6_en.init -T 15
    wget --no-check-certificate -O /www/server/panel/data/softList.conf https://github.com/mzwrt/aapanel-6.8.37-backup/blob/1fb1e5f25c75ac51b1cb132dcf4b034caa490de7/install/softList_en.conf
}
# Other_Openssl() {
#     openssl_version=$(openssl version | grep -Eo '[0-9]\.[0-9]\.[0-9]')
#     if [ "$openssl_version" = '1.0.1' ] || [ "$openssl_version" = '1.0.0' ]; then
#         opensslVersion="1.0.2r"
#         if [ ! -f "/usr/local/openssl/lib/libssl.so" ]; then
#             cd /www
#             openssl_src_file=/www/openssl.tar.gz
#             wget --no-check-certificate -O $openssl_src_file ${download_Url}/src/openssl-${opensslVersion}.tar.gz
#             tmp_size=$(du -b $openssl_src_file | awk '{print $1}')
#             if [ $tmp_size -lt 703460 ]; then
#                 rm -f $openssl_src_file
#                 Red_Error "ERROR: Download openssl-1.0.2 source code fielded."
#             fi
#             tar -zxf $openssl_src_file
#             rm -f $openssl_src_file
#             cd openssl-${opensslVersion}
#             #zlib-dynamic shared
#             ./config --openssldir=/usr/local/openssl zlib-dynamic shared
#             make -j${cpuCore}
#             make install
#             echo "/usr/local/openssl/lib" >/etc/ld.so.conf.d/zopenssl.conf
#             ldconfig
#             cd ..
#             rm -rf openssl-${opensslVersion}
#             is_export_openssl=1
#             cd ~
#         fi
#     fi
# }

# Insatll_Libressl() {
#     openssl_version=$(openssl version | grep -Eo '[0-9]\.[0-9]\.[0-9]')
#     if [ "$openssl_version" = '1.0.1' ] || [ "$openssl_version" = '1.0.0' ]; then
#         opensslVersion="3.0.2"
#         cd /www
#         openssl_src_file=/www/openssl.tar.gz
#         wget --no-check-certificate -O $openssl_src_file ${download_Url}/install/pyenv/libressl-${opensslVersion}.tar.gz
#         tmp_size=$(du -b $openssl_src_file | awk '{print $1}')
#         if [ $tmp_size -lt 703460 ]; then
#             rm -f $openssl_src_file
#             Red_Error "ERROR: Download libressl-$opensslVersion source code fielded."
#         fi
#         tar -zxf $openssl_src_file
#         rm -f $openssl_src_file
#         cd libressl-${opensslVersion}
#         ./config –prefix=/usr/local/lib
#         make -j${cpuCore}
#         make install
#         ldconfig
#         ldconfig -v
#         cd ..
#         rm -rf libressl-${opensslVersion}
#         is_export_openssl=1
#         cd ~
#     fi
# }

# Centos6_Openssl() {
#     if [ "$os_type" != 'el' ]; then
#         return
#     fi
#     if [ "$os_version" != '6' ]; then
#         return
#     fi
#     echo 'Centos6 install openssl-1.0.2...'
#     openssl_rpm_file="/www/openssl.rpm"
#     wget --no-check-certificate -O $openssl_rpm_file $download_Url/rpm/centos6/${is64bit}/bt-openssl102.rpm -T 10
#     tmp_size=$(du -b $openssl_rpm_file | awk '{print $1}')
#     if [ $tmp_size -lt 102400 ]; then
#         rm -f $openssl_rpm_file
#         Red_Error "ERROR: Download python env fielded."
#     fi
#     rpm -ivh $openssl_rpm_file
#     rm -f $openssl_rpm_file
#     is_export_openssl=1
# }


Set_Bt_Panel() {
    Run_User="www"
	wwwUser=$(cat /etc/passwd|cut -d ":" -f 1|grep ^www$)
	if [ "${wwwUser}" != "www" ];then
		groupadd ${Run_User}
		useradd -s /sbin/nologin -g ${Run_User} ${Run_User}
	fi
    chmod -R 700 /www/server/panel/pyenv/bin
    /www/server/panel/pyenv/bin/pip install cachelib
    /www/server/panel/pyenv/bin/pip install python-telegram-bot
    password=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
    if [ "$PANEL_PASSWORD" ];then
        password=$PANEL_PASSWORD
    fi
    sleep 1
    admin_auth="/www/server/panel/data/admin_path.pl"
    if [ ! -f ${admin_auth} ]; then
        auth_path=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
        echo "/${auth_path}" >${admin_auth}
    fi
    if [ "${SAFE_PATH}" ];then
        auth_path=$SAFE_PATH
        echo "/${auth_path}" > ${admin_auth}
    fi
    /www/server/panel/pyenv/bin/pip3 install pymongo
    /www/server/panel/pyenv/bin/pip3 install psycopg2-binary
    /www/server/panel/pyenv/bin/pip3 install flask -U
    /www/server/panel/pyenv/bin/pip3 install flask-sock
    /www/server/panel/pyenv/bin/pip3 install simple-websocket==0.10.0
    auth_path=$(cat ${admin_auth})
    cd ${setup_path}/server/panel/
    if [ "$SET_SSL" == true ]; then
        mkdir /www/server/panel/ssl
        /www/server/panel/pyenv/bin/pip install -I pyOpenSSl
        ssl=$(/www/server/panel/pyenv/bin/python /www/server/panel/tools.py ssl)
        echo ${ssl}
        if [ "${ssl}" -eq 0 ];then
            if [ -f "/www/server/panel/ssl/certificate.pem" ];then
                echo "Self-signed certificate fails, use the built-in SSL certificate"
                echo "True" > /www/server/panel/data/ssl.pl
            else
                SET_SSL=false
                echo "Self-signed certificate failed, panel SSl closed"
            fi
        fi
    fi
    /etc/init.d/bt start
    $python_bin -m py_compile tools.py
    $python_bin tools.py username
    username=$($python_bin tools.py panel ${password})
    if [ "$PANEL_USER" ];then
        username=$PANEL_USER
    fi
    cd ~
    echo "${password}" >${setup_path}/server/panel/default.pl
    chmod 600 ${setup_path}/server/panel/default.pl
    sleep 3
    /etc/init.d/bt restart
    sleep 3
    isStart=$(ps aux | grep 'BT-Panel' | grep -v grep | awk '{print $2}')
    LOCAL_CURL=$(curl 127.0.0.1:$panelPort/login 2>&1 | grep -i html)
    if [ -z "${isStart}" ] && [ -z "${LOCAL_CURL}" ]; then
        /etc/init.d/bt 22
        cd /www/server/panel/pyenv/bin
        touch t.pl
        ls -al python3.7 python
        lsattr python3.7 python
        Red_Error "ERROR: The BT-Panel service startup failed."
    fi

    if [ "$PANEL_USER" ];then
        cd ${setup_path}/server/panel/
        btpython -c 'import tools;tools.set_panel_username("'$PANEL_USER'")'
        cd ~
    fi
    if [ -f "/usr/bin/sqlite3" ] ;then
        #sqlite3 /www/server/panel/data/db/panel.db "UPDATE config SET status = '1' WHERE id = '1';"  > /dev/null 2>&1
        sqlite3 /www/server/panel/data/default.db "UPDATE config SET status = '1' WHERE id = '1';"  > /dev/null 2>&1
    fi
    
}
Set_Firewall() {
    sshPort=$(cat /etc/ssh/sshd_config | grep 'Port ' | awk '{print $2}')
    if [ "${PM}" = "apt-get" ]; then
        apt-get install -y ufw
        if [ -f "/usr/sbin/ufw" ]; then
            ufw allow 20/tcp
            ufw allow 21/tcp
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            ufw allow 888/tcp
            ufw allow 39000:40000/tcp
            ufw allow ${panelPort}/tcp
            ufw allow ${sshPort}/tcp
            ufw_status=$(ufw status)
            echo y | ufw enable
            ufw default deny
            ufw reload
        fi
    else
        if [ -f "/etc/init.d/iptables" ]; then
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 20 -j ACCEPT
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 21 -j ACCEPT
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport ${panelPort} -j ACCEPT
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport ${sshPort} -j ACCEPT
            iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 39000:40000 -j ACCEPT
            #iptables -I INPUT -p tcp -m state --state NEW -m udp --dport 39000:40000 -j ACCEPT
            iptables -A INPUT -p icmp --icmp-type any -j ACCEPT
            iptables -A INPUT -s localhost -d localhost -j ACCEPT
            iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
            iptables -P INPUT DROP
            service iptables save
            sed -i "s#IPTABLES_MODULES=\"\"#IPTABLES_MODULES=\"ip_conntrack_netbios_ns ip_conntrack_ftp ip_nat_ftp\"#" /etc/sysconfig/iptables-config
            iptables_status=$(service iptables status | grep 'not running')
            if [ "${iptables_status}" == '' ]; then
                service iptables restart
            fi
        else
            AliyunCheck=$(cat /etc/redhat-release | grep "Aliyun Linux")
            [ "${AliyunCheck}" ] && return
            yum install firewalld -y
            [ "${Centos8Check}" ] && yum reinstall python3-six -y
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --set-default-zone=public >/dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=20/tcp >/dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=21/tcp >/dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=22/tcp >/dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=80/tcp >/dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=443/tcp > /dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=${panelPort}/tcp >/dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=${sshPort}/tcp >/dev/null 2>&1
            firewall-cmd --permanent --zone=public --add-port=39000-40000/tcp >/dev/null 2>&1
            #firewall-cmd --permanent --zone=public --add-port=39000-40000/udp > /dev/null 2>&1
            firewall-cmd --reload
        fi
    fi
}
Get_Ip_Address() {
    getIpAddress=""
    # 	getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://brandnew.aapanel.com/api/common/getClientIP)
    getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://www.aapanel.com/api/common/getClientIP)
    # 	if [ -z "${getIpAddress}" ] || [ "${getIpAddress}" = "0.0.0.0" ]; then
    # 		isHosts=$(cat /etc/hosts|grep 'www.bt.cn')
    # 		if [ -z "${isHosts}" ];then
    # 			echo "" >> /etc/hosts
    # 			echo "103.224.251.67 www.bt.cn" >> /etc/hosts
    # 			#getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://brandnew.aapanel.com/api/common/getClientIP)
    # 			getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress)
    # 			if [ -z "${getIpAddress}" ];then
    # 				sed -i "/bt.cn/d" /etc/hosts
    # 			fi
    # 		fi
    # 	fi

    ipv4Check=$($python_bin -c "import re; print(re.match('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$','${getIpAddress}'))")
    if [ "${ipv4Check}" == "None" ]; then
        ipv6Address=$(echo ${getIpAddress} | tr -d "[]")
        ipv6Check=$($python_bin -c "import re; print(re.match('^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$','${ipv6Address}'))")
        if [ "${ipv6Check}" == "None" ]; then
            getIpAddress="SERVER_IP"
        else
            echo "True" >${setup_path}/server/panel/data/ipv6.pl
            sleep 1
            /etc/init.d/bt restart
        fi
    fi

    if [ "${getIpAddress}" != "SERVER_IP" ]; then
        echo "${getIpAddress}" >${setup_path}/server/panel/data/iplist.txt
    fi
}
Setup_Count() {
    curl -sS --connect-timeout 10 -m 60 https://www.aapanel.com/api/setupCount/setupPanel?o=$1 >/dev/null 2>&1
    # curl -sS --connect-timeout 10 -m 60 https://console.aapanel.com/Api/SetupCount?type=Linux > /dev/null 2>&1
    if [ "$1" != "" ]; then
        echo $1 >/www/server/panel/data/o.pl
        cd /www/server/panel
        $python_bin tools.py o
    fi
    echo /www >/var/bt_setupPath.conf
}

Install_Main() {
    setenforce 0
    startTime=$(date +%s)
    Lock_Clear
    System_Check
    Set_Ssl
    Get_Pack_Manager
    get_node_url

    MEM_TOTAL=$(free -g | grep Mem | awk '{print $2}')
    if [ "${MEM_TOTAL}" -le "1" ]; then
        Auto_Swap
    fi

    if [ "${PM}" = "yum" ]; then
        Install_RPM_Pack
    elif [ "${PM}" = "apt-get" ]; then
        Install_Deb_Pack
    fi

    Install_Python_Lib
    Install_Bt

    Set_Bt_Panel
    Service_Add
    Set_Firewall

    Get_Ip_Address
    Setup_Count ${IDC_CODE}
}

echo "
+----------------------------------------------------------------------
| aaPanel FOR CentOS/Ubuntu/Debian
+----------------------------------------------------------------------
| Copyright © 2015-2099 BT-SOFT(https://www.aapanel.com) All rights reserved.
+----------------------------------------------------------------------
| The WebPanel URL will be https://SERVER_IP:$panelPort when installed.
+----------------------------------------------------------------------
"

while [ ${#} -gt 0 ]; do
    case $1 in
        -u|--user)
            PANEL_USER=$2
            shift 1
            ;;
        -p|--password)
            PANEL_PASSWORD=$2
            shift 1
            ;;
        -P|--port)
            PANEL_PORT=$2
            shift 1
            ;;
        --safe-path)
            SAFE_PATH=$2
            shift 1
            ;;
        --ssl-disable)
            SSL_PL="disable"
            ;;
        -y)
            go="y"
            ;;
        *)
            IDC_CODE=$1
            ;;
    esac
    shift 1
done
while [ "$go" != 'y' ] && [ "$go" != 'n' ]; do
    read -p "Do you want to install aaPanel to the $setup_path directory now?(y/n): " go
done

if [ "$go" == 'n' ]; then
    exit
fi

Install_Main
intenal_ip=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^127\.|^255\.|^0\." | head -n 1)
echo -e "=================================================================="
echo -e "\033[32mCongratulations! Installed successfully!\033[0m"
echo -e "=================================================================="
if [ "$SET_SSL" == true ]; then
    echo "aaPanel Internet Address: https://${getIpAddress}:${panelPort}$auth_path"
    echo "aaPanel Internal Address: https://${intenal_ip}:${panelPort}$auth_path"
else
    echo "aaPanel Internet Address: http://${getIpAddress}:${panelPort}$auth_path"
    echo "aaPanel Internal Address: http://${intenal_ip}:${panelPort}$auth_path"
fi
echo -e "username: $username"
echo -e "password: $password"
echo -e "\033[33mWarning:\033[0m"
echo -e "\033[33mIf you cannot access the panel, \033[0m"
echo -e "\033[33mrelease the following port ($panelPort|888|80|443|20|21) in the security group\033[0m"
echo -e "=================================================================="

endTime=$(date +%s)
((outTime = ($endTime - $startTime) / 60))
echo -e "Time consumed:\033[32m $outTime \033[0mMinute!"
rm -f install-ubuntu_6.0_en.sh
