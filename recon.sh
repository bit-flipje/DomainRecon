#!/bin/bash

if [ -z "$1" ]
then
        echo "use: ./recon.sh <domain>"
        exit 1
fi


printf "start scan $1\n\n"

export TARGET="$1"

#theHarverster
printf "starting theHarvester\n\n"


cat sources.cfg | while read source; do theHarvester -d "${TARGET}" -b $source -f "${source}_${TARGET}";done

printf "starting sublist3r\n\n"

sublist3r -d "${TARGET}" -o json -o sublist3r.output.json
sort -u "sublist3r.output.json" >> "${TARGET}_domains.txt"

#FUFF DNS recon
#Nederlandse wordlist
#ffuf -w domain-wordlist-dutch:FUZZ -u https://FUZZ.$TARGET -o "$TARGET"_domain_ffuf.json

#international wordlist
ffuf -w /opt/SecLists/Discovery/DNS/subdomains-top1million-20000.txt:FUZZ -u https://FUZZ.$TARGET -o "$TARGET"_domain_ffuf.json

printf "creating domainlist.txt\n\n"

#Samenvoegen json input files naar 1 output file
cat *.json | jq -r '.hosts[]' 2>/dev/null | cut -d':' -f 1 | sort -u >> "${TARGET}_domains.txt"


#starting Amass scanner

printf "Starting amass scanner\n\n"

amass enum -passive -d $TARGET -timeout 5 > "amassoutput_$TARGET"
cat "amassoutput_$TARGET" | grep -o "[A-Za-z0-9_\.-]*.${TARGET}" | >> "${TARGET}_domains.txt"
printf "amass finished\n\n"

#Start assetfinder
printf "running assetfinder\n\n"
assetfinder $TARGET > "assetfinder.$TARGET.json"
sort -u "assetfinder.$TARGET.json" >> "${TARGET}_domains.txt"
printf "assetfinder finished\n\n"

#bestanden naar lowercase zetten:
printf "magic happening\n\n"
tr '[:upper:]' '[:lower:]' < "${TARGET}_domains.txt" > "${TARGET}_domains.lower.txt"
sort -u "${TARGET}_domains.lower.txt" >> "${TARGET}_domains_sorted.txt"



#cleanup
rm *.json
rm *.xml

printf "recon finished\n\n"

