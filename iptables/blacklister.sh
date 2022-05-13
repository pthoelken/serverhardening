#!/bin/bash -e
export PATH="/bin:/usr/bin:/sbin:/usr/sbin"

strChainName=BLACKLIST
strChainNameLOG=INPUT-DROP-LOG
strWorkingDirectory=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
strBlacklistFolder=$strWorkingDirectory/blacklists
strLogFolder=$strWorkingDirectory/logs
strConsoleLogFile=$strLogFolder/ip-blacklister-console.log
strBlacklistFile=$strBlacklistFolder/blacklist
strBlacklistTempFile=$strBlacklistFolder/tmp-blacklist
strDDOSProtectionLockFile=$strWorkingDirectory/ddos.ruleset.lock

intBlacklistingINPUTLineNo=$(iptables -n --list INPUT --line-numbers | grep -i $strChainName | sed -e 's/^\(.\{2\}\).*/\1/')
objLOGChainCheck=$(iptables -nvL | grep -i $strChainNameLOG )

function ConsoleLog() {

    if [ ! -d $strLogFolder ]; then
        mkdir -p $strLogFolder
    fi

    echo "[ $(date) ] | $1 " | tee -a $strConsoleLogFile
}

function ApplicationCheck(){
    which "$1" | grep -o "$1" > /dev/null &&  return 0 || return 1 
}

function CheckRuntimePreparing(){
    aryApplications=( iptables iptables-save ipset wget tee fail2ban )
    aryFolders=( $strBlacklistFolder )

    for objApps in "${aryApplications[@]}"; do
        if ( ! ApplicationCheck $objApps ); then
            ConsoleLog "$objApps not found .. install ipset, iptables and iptables-save on your server"
            exit 1
        fi
    done

    for objFolders in "${aryFolders[@]}"; do
        if [ ! -d $objFolders ]; then
            mkdir -p $objFolders
        fi
    done
}

function PrepareBacklist() {
    if [ -f $strBlacklistFile ]; then
        rm -rf $strBlacklistFile
    fi
        wget http://lists.blocklist.de/lists/all.txt -O $strBlacklistTempFile
        grep -v ":" $strBlacklistTempFile > $strBlacklistFile
        rm -rf $strBlacklistTempFile
}

function LogChainConfiguration() {
    if [ -z "$intBlacklistingINPUTLineNo" ]; then
        iptables -N $strChainNameLOG
        iptables -I $strChainNameLOG 1 -j LOG -m limit --limit 5/s --log-prefix "NETFILTER DROP INBOUND : "
        iptables -A $strChainNameLOG -j DROP
        ConsoleLog "Chain $strChainNameLOG successfully created ..."
    else
        ConsoleLog "All fine, chain $strChainNameLOG already found in iptables ..."
    fi
}

function ddosProectionRules() {
    if [ ! -f $strDDOSProtectionLockFile ]; then

        iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
        iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
        iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
        iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
        iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
        iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
        iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
        iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
        iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
        iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
        iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP
        iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP
        iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP
        iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP
        iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP
        iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP
        iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP
        iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP
        iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP
        iptables -t mangle -A PREROUTING -p icmp -j DROP
        iptables -t mangle -A PREROUTING -f -j DROP
        iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset
        iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
        iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP
        iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
        iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
        iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set
        iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
        iptables -N port-scanning
        iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
        iptables -A port-scanning -j DROP

        echo "[ $(date) ] | Initialization of ddos protection rulset complete ..." | tee -a $strDDOSProtectionLockFile
    else
        echo "[ $(date) ] | Latest ddos protection rulset check ... protection already set ..." | tee -a $strDDOSProtectionLockFile
    fi
}

ConsoleLog "Check LOG chain configuration ..."
LogChainConfiguration

ConsoleLog "Check runtime preparing for ip-blacklister ..."
CheckRuntimePreparing

ConsoleLog "Download new blacklists ..."
PrepareBacklist >> /dev/null 2>&1

ConsoleLog "Stopping fail2ban services ..."
service fail2ban stop >> /dev/null 2>&1

ConsoleLog "Flush or create ipset $strChainName table ..."
if ! ipset flush $strChainName ; then
    ipset create $strChainName hash:ip
fi

ConsoleLog "Importing blacklisted ip addresses from allblacklist ..."
while IFS= read -r ipAddress
do
    ipset add $strChainName $ipAddress
done < "$strBlacklistFile"

ConsoleLog "Purging old blacklists ..."
rm -rf $strBlacklistFolder/*.* >> /dev/null 2>&1

ConsoleLog "Checking INPUT rule for inserting  of $strChainName on 1 ..."
if [ -z "$intBlacklistingINPUTLineNo" ]; then
    iptables -I INPUT 1 -m set --match-set $strChainName src -j $strChainNameLOG >> /dev/null 2>&1
    ConsoleLog "Rule-set $strChainName successfully insert in chain INPUT to 1 with jump to $strChainNameLOG ..."
else
    ConsoleLog "All fine, rule-set $strChainName already found in chain INPUT ..."
fi

ConsoleLog "Executing ddos procetion ruleset configuration ..."
ddosProectionRules >> /dev/null 2>&1

ConsoleLog "iptables-save makes iptables rules persistent ..."
iptables-save >> /dev/null 2>&1

ConsoleLog "Starting fail2ban services ..."
service fail2ban start >> /dev/null 2>&1

exit 0
