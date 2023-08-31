#! /bin/bash
#===============================================================================================
#   System Required:  CentOS (32bit/64bit)
#   Description:  A tool to auto-compile & install nps on Linux
#   Author: LZ_CN
#   Intro:  http://www.hdsytl.cn:9093
#===============================================================================================
# GitHub API endpoint for the repository
REPO_OWNER="ehang-io"
REPO_NAME="nps"
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
Localhost_IP=$(wget -qO- ip.clang.cn | sed -r 's/\r//')
# Send a GET request to the GitHub API and store the response in a variable
response=$(curl -s "$GITHUB_API")

# Parse the JSON response to extract the latest release's download URL
latest_download_url=$(echo "$response" | grep -Eo '"browser_download_url": "([^"]+)"' | cut -d'"' -f4)
fun_ehang-io() {
    echo ""
    echo "+---------------------------------------------------------+"
    echo "|        nps for Linux Server, Written by LZCN            |"
    echo "+---------------------------------------------------------+"
    echo "|   A tool to auto-compile & install nps on Linux         |"
    echo "+---------------------------------------------------------+"
    echo "|        Intro: http://www.hdsytl.cn:9093                 |"
    echo "+---------------------------------------------------------+"
    echo ""
}

# Check the necessary conditions before installation
fun_check() {
     wget --version &> /dev/null
     if [ $? -eq 0 ]; then
	echo " Check Security! -wget"
    else
        yum install -y wget &> /dev/null
    fi
   
     tar --version &> /dev/null
     if [ $? -eq 0 ]; then
        echo " Check Security! -tar"
    else
        yum install -y tar &> /dev/null
    fi

    netstat --version &> /dev/null
    if [ $? -eq 0 ]; then
        echo " Check Security! -netstat"
    else
        yum install -y net-tools &> /dev/null
    fi
}


#Select the installed version
fun_getServer() {
    def_system="linux"
    def_download_version="amd64"
    optional_download_version="arm64"
    echo ""
    echo -e "github (default download url)"
    echo -e "Please select ${REPO_NAME} download version:"
    echo -e "[1].amd64 (default)"
    echo -e "[2].arm64"
    read -e -p "Enter your choice (1, 2 or exit. default [${def_download_version}]): " set_download_version
    case "${set_download_version}" in
        1|[amd64])
           nps_download=`echo "$latest_download_url" | grep ${def_system}_${def_download_version}_server`
	   nps_download_fast="${nps_download/github.com/githubfast.com}"
	   wget --no-check-certificate ${nps_download_fast}
	   ;;
        2|[arm64])
            nps_download=`echo "$latest_download_url" | grep ${def_system}_${optional_download_version}_server`
	    nps_download_fast="${nps_download/github.com/githubfast.com}"
	    wget --no-check-certificate ${nps_download_fast}
            ;;
        [exit])
            exit 1
            ;;
        *)
	   nps_download=`echo "$latest_download_url" | grep ${def_system}_${def_download_version}_server`
           nps_download_fast="${nps_download/github.com/githubfast.com}"
           wget --no-check-certificate ${nps_download_fast}	
            ;;
    esac
}

fun_unzip() {
    nps_tar=`echo " ${nps_download}" | awk -F "/" '{print $9}'`
    tar -xvf ${nps_tar} &> /dev/null
    ./nps install
}

fun_http_proxy_ip() {
    def_http_proxy_ip="0.0.0.0"
    def_nps_file="/etc/nps/conf/nps.conf"
        while true; do
           echo ""
           echo -n -e "Please input ${REPO_NAME} http_proxy_ip [0.0.0.0~255.255.255.255]"		
           read -p "[Default Ip: ${def_http_proxy_ip}]:" set_http_proxy_ip
               if [[ ${set_http_proxy_ip} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                     valid_ip=true
                     IFS='.' read -ra ip_fields <<< "${set_http_proxy_ip}"
           for field in "${ip_fields[@]}"; do
               if ((field < 0 || field > 255)); then
                     valid_ip=false
                     break
               fi
           done

               if [ "${valid_ip}" = true ]; then
                     sed -r -i "s#(^http_proxy_ip=)(.*)#\1${set_http_proxy_ip}#" ${def_nps_file}
		     break
           else
                     echo "Invalid IP address. Please enter a valid IPv4 address."
               fi
           else
                     echo "Invalid format. Please enter a valid IPv4 address."
               fi
       done

}

fun_http_proxy_port() {
    def_http_proxy_port="80"
    
    while true; do
	echo ""
	echo -n -e "Please input ${REPO_NAME} http_proxy_port [1-65535]"
        read -p "[Default Server Port: ${def_http_proxy_port}]:" set_http_proxy_port
        
        if [[ ${set_http_proxy_port} =~ ^[1-9][0-9]{0,4}$ ]]; then
            if ((set_http_proxy_port >= 1 && set_http_proxy_port <= 65535)); then
                port_in_use=$(netstat -antup | awk -v port="${set_http_proxy_port}" '$6 == "LISTEN" && $4 ~ ":"port"$" {print $0}')
                if [ -z "$port_in_use" ]; then
                    sed -r -i "s#(^http_proxy_port=)(.*)#\1${set_http_proxy_port}#" ${def_nps_file}
                    break
                else
                    echo "Port is already in use"
                fi
            else
                echo "Port is out of range [1-65535]."
            fi
        else
            echo "Invalid port format."
        fi
    done
}

fun_https_proxy_port() {
    def_https_proxy_port="443"

    while true; do
	echo ""
        echo -n -e "Please input ${REPO_NAME} https_proxy_port [1-65535]"    
        read -p "[Default Server Port: ${def_https_proxy_port}]:" set_https_proxy_port

        if [[ ${set_https_proxy_port} =~ ^[1-9][0-9]{0,4}$ ]]; then
            if ((set_https_proxy_port >= 1 && set_https_proxy_port <= 65535)); then
                port_in_use=$(netstat -antup | awk -v port="${set_https_proxy_port}" '$6 == "LISTEN" && $4 ~ ":"port"$" {print $0}')
                if [ -z "$port_in_use" ]; then
                    sed -r -i "s#(^https_proxy_port=)(.*)#\1${set_https_proxy_port}#" ${def_nps_file}
                    break
                else
                    echo "Port is already in use"
                fi
            else
                echo "Port is out of range [1-65535]."
            fi
        else
            echo "Invalid port format."
        fi
    done
}

fun_bridge_port() {
    def_bridge_port="8024"

    while true; do
	echo ""
        echo -n -e "Please input ${REPO_NAME} bridge_port [1-65535]"     
        read -p "[Default Server Port: ${def_bridge_port}]:" set_bridge_port

        if [[ ${set_bridge_port} =~ ^[1-9][0-9]{0,4}$ ]]; then
            if ((set_bridge_port >= 1 && set_bridge_port <= 65535)); then
                port_in_use=$(netstat -antup | awk -v port="${set_bridge_port}" '$6 == "LISTEN" && $4 ~ ":"port"$" {print $0}')
                if [ -z "$port_in_use" ]; then
                    sed -r -i "s#(^bridge_port=)(.*)#\1${set_bridge_port}#" ${def_nps_file}
                    break
                else
                    echo "Port is already in use"
                fi
            else
                echo "Port is out of range [1-65535]."
            fi
        else
            echo "Invalid port format."
        fi
    done
}


fun_web_username() {
    def_web_username="admin"
    echo ""
    echo -n -e "Please input ${REPO_NAME} web_username" 
    read -p "[Default Web Username: ${def_web_username}]: " set_web_username

while [[ -z "$set_web_username" ]]; do
    read -p "Username cannot be empty. Please enter a valid username: " set_web_username
    sed -r -i "s#(^web_username=)(.*)#\1${set_web_username}#" ${def_nps_file}
done 

}

generate_random_password() {
    password_length=16

    password=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c$password_length; echo)
    
    echo "${password}"
}

fun_web_password() {
    random_password=$(generate_random_password)
    sed -r -i "s#(^web_password=)(.*)#\1${random_password}#" ${def_nps_file}
}

fun_web_port() {
    def_web_port="8080"

    while true; do
        echo ""
        echo -n -e "Please input ${REPO_NAME} web_port [1-65535]"     
        read -p "[Default Server Port: ${def_web_port}]:" set_web_port

        if [[ ${set_web_port} =~ ^[1-9][0-9]{0,4}$ ]]; then
            if ((set_web_port >= 1 && set_web_port <= 65535)); then
                port_in_use=$(netstat -antup | awk -v port="${set_web_port}" '$6 == "LISTEN" && $4 ~ ":"port"$" {print $0}')
                if [ -z "$port_in_use" ]; then
                    sed -r -i "s#(^web_port = )(.*)#\1${set_web_port}#" ${def_nps_file}
                    break
                else
                    echo "Port is already in use"
                fi
            else
                echo "Port is out of range [1-65535]."
            fi
        else
            echo "Invalid port format."
        fi
    done
}

fun_web_ip() {
    def_web_ip="0.0.0.0"
        while true; do
           echo ""
           echo -n -e "Please input ${REPO_NAME} web_ip [0.0.0.0~255.255.255.255]"               
           read -p "(Default  Ip: ${def_web_ip}):" set_web_ip
               if [[ ${set_web_ip} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                     valid_ip=true
                     IFS='.' read -ra ip_fields <<< "${set_web_ip}"
           for field in "${ip_fields[@]}"; do
               if ((field < 0 || field > 255)); then
                     valid_ip=false
                     break
               fi
           done

               if [ "${valid_ip}" = true ]; then
                     sed -r -i "s#(^web_ip=)(.*)#\1${set_web_ip}#" ${def_nps_file}
                     break
           else
                     echo "Invalid IP address. Please enter a valid IPv4 address."
               fi
           else
                     echo "Invalid format. Please enter a valid IPv4 address."
               fi
       done

}

generate_random_password_plus() {
    password_length=32

    password_plus=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c$password_length; echo)

    echo "${password_plus}"
}


fun_public_vkey() {
    random_password_plus=$(generate_random_password_plus)
    sed -r -i "s#(^public_vkey=)(.*)#public_vkey=${random_password_plus}#" ${def_nps_file}
}


fun_auth_key() {
    random_password_plus=$(generate_random_password_plus)
    sed -r -i "s#(.*)(auth_key=)(.*)#auth_key=${random_password_plus}#" ${def_nps_file}
}


fun_auth_crypt_key() {
    random_password_plus=$(generate_random_password_plus)
    sed -r -i "s#(^auth_crypt_key =)(.*)#auth_crypt_key=${random_password_plus}#" ${def_nps_file}
}

fun_nps_start() {
    nps start
}

fun_nps_view_list() {

   web_password_list=`cat ${def_nps_file} | grep  web_password | awk -F "=" '{print $2}'`
   public_vkey_list=`cat ${def_nps_file} | grep  public_vkey | awk -F "=" '{print $2}'`
   auth_key_list=`cat ${def_nps_file} | grep  auth_key | awk -F "=" '{print $2}'`
   auth_crypt_key_list=`cat ${def_nps_file} | grep  auth_crypt_key | awk -F "=" '{print $2}' | sed '/^\s*$/d'`

   echo "Setting completed !"
        echo ""
        echo "============== nps view list =============="
        echo -e "local_ip           : ${Localhost_IP}"
        echo -e "http_proxy_ip      : ${set_http_proxy_ip}"
        echo -e "http_proxy_port    : ${set_http_proxy_port}"
        echo -e "https_proxy_port   : ${set_https_proxy_port}"
        echo -e "bridge_port        : ${set_bridge_port}"
        echo -e "web_username       : ${set_web_username}"
        echo -e "web_password       : ${web_password_list}"
        echo -e "web_port           : ${set_web_port}"
        echo -e "web_ip             : ${set_web_ip}"
        echo -e "public_vkey        : ${public_vkey_list}"
        echo -e "auth_key           : ${auth_key_list}"
        echo -e "auth_crypt_key     : ${auth_crypt_key_list}"
        echo "=============================================="
        echo ""
}


fun_nps_uninstall() {
      nps stop
      rm -rf /etc/nps/ 
      nps_uninstall=`find / -name "nps.conf" -exec dirname {} \; 2>/dev/null | xargs -I {} dirname {}`
      rm -rf ${nps_uninstall}/web
      rm -rf ${nps_uninstall}/nps
      rm -rf ${nps_uninstall}/conf
      rm -rf ${nps_uninstall}/linux_amd64_server.tar.gz
      echo "Uninstall Complete !"
}



action="$1"
case "$action" in

install)
fun_ehang-io
fun_check
fun_getServer
fun_unzip
fun_http_proxy_ip
fun_http_proxy_port
fun_https_proxy_port
fun_bridge_port
fun_web_username
fun_web_password
fun_web_port
fun_web_ip
fun_public_vkey
fun_auth_key
fun_auth_crypt_key
fun_nps_start
fun_nps_view_list
;;

uninstall)
fun_nps_uninstall

;;

*)
fun_ehang-io
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    RET_VAL=1
;;
esac
