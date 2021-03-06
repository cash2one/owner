#!/bin/bash
#set -x
if [ $# -ne 2 ]; then                                
	echo "命令格式错误 $0 资源svn地址 发布目的地"       
	echo "例如: $0 http://172.16.0.2/svn/3d_client/trunk/client/BuildRes imo"
	exit 1                                           
fi                                                   

original_path=`pwd`
server_version=$1
svn_username=imane
svn_passwd=imane
tmp_file=tmp_`date +%Y%m%d-%H%M%S`_pid$$

main_path=`basename $server_version`
echo "现在检查资源工作目录"
if [ ! -d $main_path ]
then
	echo "现在开始创建服务器工作目录"
	svn co --non-interactive --username=$svn_username --password=$svn_passwd $server_version 
	if [ $? -ne 0 ]
	then
		echo "创建svn工作目录失败，请联系服务器研发工程师"
		exit 1
	fi
fi

cd $main_path
echo "现在更新资源工作目录"
svn up --non-interactive --username=$svn_username --password=$svn_passwd | tee /tmp/$tmp_file
if [ $? -ne 0 ]
then
	echo "更新svn失败，请联系服务器研发工程师"
	exit 1
fi
if grep /tmp/$tmp_file 'Text conflicts'
then
	echo "更新svn冲突, 请联系服务器研发工程师"
	exit 1
fi

name=`svn info | grep -E 'Last Changed Rev|最后修改的版本' | cut -d: -f 2 | cut -c 2-`
if [ a$name = "a" ]
then
	echo "svn info get version fail"
	exit 1
fi
cd ../
if [ -e $name ]; then
	rm -rf $name
fi

address=''
password=''
case $2 in
	"inner" )
		address="ime@172.16.0.89:/home/ime/packet"
		password="ime@server";;
	* )
		echo "zone para must be [imo, inner, outer, xd_imo, zhw_imo]"
		exit 1
esac

mkdir $name
cp -r $main_path/* $name
cd $name
find . -name .svn -exec rm -rf {} \; >& /dev/null
cd ../

echo "================ launch res $name ================="

expect -c "
set timeout -1
spawn scp -r -o StrictHostKeyChecking=no $name $address
expect *assword*
send $password\n
expect eof
"

cd $original_path
