#!/bin/sh

# Begin functions
# Print out the help
__usage(){
    echo "usage: password_extractor [-o output_file | [-h]]"
}

#           | grep -Eo '"WordText":.*?[^\\]",' \

__extract_pwd(){
        local file="$@"
        local pwd=$(cat ${output_file} \
            | grep -Eo '"LineText":.*?[^\\]",' \
            | awk -F':' '{print $2}' \
            | awk -F',' '{print $1}' \
            | awk '{ gsub(/^[ \t]+|[ \t]+$/, ""); print }' \
            | sed 's/[^a-zA-Z0-9]//g' \
            | tr -d \")
    echo ${pwd##*|}
}
# End functions

debug_flag=0
vpnbook_folder=$HOME/.vpnbook
vpnbook_base_url=https://www.vpnbook.com
vpnbook_url=${vpnbook_base_url}/freevpn
tesseract_service_url=https://api.ocr.space/parse/image
timestamp=$(date +%s)
output_file=/tmp/vpnbok_pwd_${timestamp}.json
log_file=/tmp/vpnbok_pwd_${timestamp}.log

# Start Script
while [ "$1" != "" ]; do
    case $1 in
        -o | --output )         shift
                                output_file=$1
                                ;;
        -d | --debug )          shift
                                debug_flag=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

echo "Content-type:text/plain"
echo ""
# Retrieve the Password URL from the official webpage
pwd_url=$(curl -s ${vpnbook_url} | grep -m2 "Password:" | tail -n1 | cut -d \" -f2)
#echo "Retrieving Password at the following URL: ${vpnbook_base_url}/${pwd_url}"

curl -X POST --header "apikey: 243ef8209c88957" \
-F "url=${vpnbook_base_url}/${pwd_url}" \
-F 'language=eng' \
-F 'isOverlayRequired=true' \
-F 'FileType=.Auto' \
-F 'IsCreateSearchablePDF=false' \
-F 'isSearchablePdfHideTextLayer=true' \
-F 'scale=true' \
-F 'detectOrientation=false' \
-F 'isTable=false' \
${tesseract_service_url} -o ${output_file}

#sed -i 's/ //g' ${output_file}
#sed -i 's/\•//g' ${output_file}

pwd=$(__extract_pwd ${output_file})
echo ${pwd} > ${output_file}

#echo 'Retrieved password:---'${pwd}'---'
#echo "${pwd}"
tr -d "\n\r" < ${output_file}

exit 0;