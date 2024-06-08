# aapanel-6.8.37-backup

使用方法：

安装/install：

     wget  https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/install.sh && bash install.sh

升级降级/Upgrading：

     wget  https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/update.sh && bash update.sh

纯官方版，无任何改动


删除默认添加的以下端口

             ufw allow 20/tcp
            ufw allow 21/tcp
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            ufw allow 888/tcp
            ufw allow 39000:40000/tcp

默认只添加ssh端口和面板端口
