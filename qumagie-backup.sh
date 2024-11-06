#!/bin/bash
# ------------------------------------------------------------
# QuMagie qnap-qumagie-face-data
# 作用：此脚本用备份 QuMagie 相册程序的人像数据
# 作者：bbis
# Website：https://cheen.cn
# GitHub：https://github.com/iranee
# 日期：2024-11-06
# ------------------------------------------------------------
QPKG_CONF=/etc/config/qpkg.conf
QPKG_NAME="qumagie"
ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $QPKG_CONF)
if [ "$ENABLED" != "TRUE" ]; then
    echo "QuMagie程序未启用，退出脚本程序。"
    exit 1
fi

export_type="metadata"
target_folder="备份/照片备份/QuMagie" # 备份路径，在/share/目录下的文件夹
uname="admin" # 默认值
password="" # 实际使用时请替换为实际密码

split="500g" # 单个文件大小
uid=0 # 默认值
backup_date=$(date +"%Y%m%d%H%M%S")
job_id="dmt${backup_date}34ef25952da33cd33"
serverName="$(getcfg System 'Server Name' -d NAS -f /etc/config/uLinux.conf)"
target_file="${uname}-${serverName}-${backup_date}-$( [ "$export_type" = 'full' ] && echo "data" || echo "metadata" ).qumagie"
if [ "$uname" != "admin" ]; then
    uid=$(grep "^$uname:" /etc/passwd | cut -d":" -f3)
    if [ -z "$uid" ]; then
        echo "用户 $uname 不存在。"
        exit 1
    fi
fi

cleanup() {
    kill "$backup_pid" 2>/dev/null
    wait "$backup_pid" 2>/dev/null
    echo "备份进程已停止。"
	exit 1
}

trap cleanup EXIT INT

mkdir /mnt/ext/opt/station_config/qumagie/dmt/export_$job_id
echo "" >> "/mnt/ext/opt/station_config/qumagie/dmt/export_$job_id/status"

/usr/local/bin/qm_export t=$export_type d=$target_folder s=$split uname=$uname u=$uid p=qnapqnap$password id=$job_id f=$target_file > /dev/null 2>&1 &
backup_pid=$!

status_file="/mnt/ext/opt/station_config/qumagie/dmt/export_$job_id/status"
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
echo 
while true; do
    if [ -f "$status_file" ]; then

		total_entries=$(jq '.total_entries' "$status_file" | tr -d '"')
        processed=$(jq '.processed' "$status_file" | tr -d '"')
        progress=$(jq '.progress' "$status_file" | sed 's/[^0-9.]//g')
        status=$(jq '.status' "$status_file" | tr -d '"')
        
        if [ -z "$status" ] || [ "$status" == "null" ]; then
            status="索引中..."
        elif [ "$status" == "zipping" ]; then
            status="正在压缩..."
        elif [ "$status" == "complete" ]; then
            status="备份完成！"
        fi

        echo -ne "总文件数: ${GREEN}${total_entries}${NC}, 已处理: ${RED}${processed}${NC}, 状态: ${status}  进度: ${GREEN}${progress}${NC}\r"
        if [ "$status" == "备份完成！" ] && [ "$progress" == "100" ]; then
            echo
            break
        fi
    else
        echo -ne "索引中...\r"
    fi
    sleep 2
done

get_prefix_path=$(/usr/local/medialibrary/bin/mymediadbcmd getsvrconf2 -i 5)
path=$(echo "$get_prefix_path" | jq -r '.result.apps[0].dirs[0].path')
prefix=$(echo "$get_prefix_path" | jq -r '.result.apps[0].dirs[0].prefix')
Photos_full_path="${prefix}${path}"
processed=$(jq '.processed' /mnt/ext/opt/station_config/qumagie/dmt/export_$job_id/status)
backup_file_name="/share/$target_folder/$target_file.001"
#rm -rf /mnt/ext/opt/station_config/qumagie/dmt/*

echo "---------------------------------------------
${backup_date:0:4}-${backup_date:4:2}-${backup_date:6:2} ${backup_date:8:2}:${backup_date:10:2}:${backup_date:12:2}
相册用户：$uname
数据类型：$export_type
相册路径: $Photos_full_path
备份文件数量: $processed
备份文件路径：$backup_file_name
密码：qnapqnap$password" | tee -a /share/$target_folder/logfile.log
