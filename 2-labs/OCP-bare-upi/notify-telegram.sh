#!/bin/bash

if [ $# -ne 6 ];
    then echo "Illegal number of parameters, usage:"
    echo ""
    echo "$0 --token fdsalkjfdsalkfhasdlfkhasdflkhasdf --chat-id 432432432 --message  '*Deployment*\nStatus: *OK*\nCompleted'"
    echo ""
    exit 1
fi

while [[ $# -gt 0 ]] && [[ ."$1" = .--* ]] ;
do
    opt="$1";
    shift;              #expose next argument
    case "$opt" in
        "--" ) break 2;;
        "--token" )
           token=$1; shift;;
        "--chat-id" )
           chat_id=$1; shift;;
        "--message" )
           message=$1; shift;;

   esac
done


echo "token $token"
echo "chat-id $chat_id"
echo "message $message"


tmpfile=$(mktemp /tmp/telebot.XXXXXXX)
cat > $tmpfile <<EOF
{"chat_id":"$chat_id", "parse_mode":"markdown", "text":"$message"}
EOF

curl -k --header 'Content-Type: application/json' \
		--data-binary @${tmpfile} \
		--request POST https://api.telegram.org/$token/sendMessage

rm -f $tmpfile
