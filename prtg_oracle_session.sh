#!/bin/bash
# 準備執行 SQLPlus 需要的環境變數
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export ORACLE_SID=XE
export NLS_LANG=`$ORACLE_HOME/bin/nls_lang.sh`
export PATH=$ORACLE_HOME/bin:$PATH
if [ "$1" == '' ]; then
   exit
fi

# 將 SQLPlus 執行的結果拼湊成 PRTG HTTP Push Data Advanced Sensor 需要的 XML 格式輸出
prtg=$(/u01/app/oracle/product/11.2.0/xe/bin/sqlplus -s /nolog <<BEGIN_S
CONNECT omni/omni
SET FEEDBACK off 
SET PAGESIZE 0 
select '<prtg>' from dual;
set serveroutput on;
declare
    l_group varchar2(100);
    l_count number;
    cursor session_cur is
    select $1, count(*) ccc into l_group, l_count from v\$session group by $1;
begin
    open session_cur;
    loop
    fetch session_cur into l_group, l_count;
    exit when session_cur%NOTFOUND;
        dbms_output.put_line('<result>');
        dbms_output.put_line('<channel>'|| nvl(l_group,'NULL') ||'</channel>');
        dbms_output.put_line('<value>'|| l_count ||'</value>');
        dbms_output.put_line('</result>');
    end loop;
end;
/
select '</prtg>' from dual;
BEGIN_S
)
# 印出 XML 檢查結果
echo $prtg
# PRTG HTTP Push Data Advanced Sensor 監聽的網址
url="http://192.168.20.49:5050/$1$2"
# 印出網址檢查結果
echo $url
# 使用 curl 將資料 POST 給 PRTG Probe
/usr/bin/curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -s -k -m 10 "$url" -d "content=$prtg"
echo
