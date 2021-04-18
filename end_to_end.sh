# Help output
if [ "$1" = "-h" -o "$1" = "--help" -o -z "$1" ]; then cat <<EOF
ZAP script for Lab 5
CYB600 - Secure Software Engineering
Canisius College
Usage: end_to_end.sh -k <API key> -t <web address of target> -f <name of student subfolder>
ex. ./end_to_end.sh -k "94t3u98tu9u984tugru8e9hu9ehu9e" -t "http://vulnerablewebapp.legaltohack.com" -f "josh"
Optional arguments: -p <port number> -n (do not run the server)
To get your API key, start the OWASP ZAP UI and go to Tools -> Options -> API
If you run into issues with the ZAP API server, kill all instances of the server with 'killall java'
Copyright 2021 Justin Del Vecchio | Modified by Steve Nemeti <https://github.com/snem1216>
EOF
exit; fi
unset ZAP_API_KEY
unset ZAP_TARGET
unset ZAP_NO_DAEMON
unset ZAP_PORT
unset ZAP_HTML_OUTPUT_FOLDER
E2E_BASEDIR=$(dirname "$0")
ZAP_NO_DAEMON=0
while getopts ":t:k:p:nf:" opt; do
  case $opt in
    # API Key
    k) ZAP_API_KEY="$OPTARG"
    ;;
    # Port
    p) ZAP_PORT="$OPTARG"
    ;;
    # Target
    t) ZAP_TARGET="$OPTARG"
    ;;
    # No daemon - server already running
    n) ZAP_NO_DAEMON=1
    ;;
    # Student folder
    f) ZAP_HTML_OUTPUT_FOLDER="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done
if [ -z "$ZAP_API_KEY" ]; then
        echo 'Missing API Key argument -k' >&2
        exit 1
fi
if [ -z "$ZAP_TARGET" ]; then
        echo 'Missing target argument -t' >&2
        exit 1
fi
if [ -z "$ZAP_HTML_OUTPUT_FOLDER" ]; then
        echo 'Missing student folder argument -f' >&2
        exit 1
fi
if [ $ZAP_NO_DAEMON -eq 0 ]; then
        # Make set the executable depeding on OS
        if [ $(uname) == "Darwin" ]; then ZAP_EXECUTABLE="/Applications/OWASP ZAP.app/Contents/MacOS/OWASP ZAP.sh"; elif [ $(uname) == "Linux" ]; then ZAP_EXECUTABLE="/opt/zaproxy/zap.sh"; else echo "Unsupported operating system \"$(uname)\", was expecting 'Linux' or 'Darwin'."; exit 1; fi
        if [ ! -f $ZAP_EXECUTABLE ]; then echo "Missing expected $(uname) ZAP executable at \"$ZAP_EXECUTABLE\"."; echo "Please double check your installation and modify this script if necessary."; exit 1; fi
        echo "Start the ZAP daemon..."
        nohup $ZAP_EXECUTABLE -daemon &
        echo "Sleeping for 20 seconds to make sure it is initialized."
        sleep 10
fi
# If the port is not manually set by the user, try to get it automatically or fall back to the default value.
if [ -z "$ZAP_PORT" ]; then
        # Attempt to retrieve port number from nohup output
        if [ -f "./nohup.out" ]; then
            ZAP_PORT=$(cat nohup.out | grep -o -E 'listening on localhost:[0-9]+' | tail -n 1 | grep -o -E '[0-9]+')
            echo "AUTODETECT PORT $ZAP_PORT"
        fi
        # Fall back to the default value
        if [ -z "$ZAP_PORT" ]; then
            ZAP_PORT="8080"
            echo "Defaulting port number"
        fi
fi

echo "Checking the status of the local ZAP server..."
curl "http://localhost:$ZAP_PORT"
# If the connection fails, exit with curl's returned error code.
if [ $? -eq 1 ]; then echo "Error: Could not contact localhost on port $ZAP_PORT. Check nohup.output for errors."; exit $?; fi

echo "Spider scan for the web site"
curl "http://localhost:$ZAP_PORT/JSON/spider/action/scan/?apikey=$ZAP_API_KEY&zapapiformat=JSON&formMethod=GET&url=$ZAP_TARGET"
echo "Wait for 20 sec to complete the Scan before moving to Active scan"
sleep 20

echo "Active Scan for the website"
curl "http://localhost:$ZAP_PORT/JSON/ascan/action/scan/?apikey=$ZAP_API_KEY&zapapiformat=JSON&formMethod=GET&url=$ZAP_TARGET&recurse=&inScopeOnly=&scanPolicyName=&method=&postData=&contextId="
echo "Wait for 20 sec to complete the ActiveScan before generating the testing report"
sleep 20

echo "List the security assessments results (alerts), and output the report to $E2E_BASEDIR/$ZAP_HTML_OUTPUT_FOLDER/ZAP_Report.HTML"
mkdir -p ./$ZAP_HTML_OUTPUT_FOLDER
curl "http://localhost:$ZAP_PORT/JSON/ascan/view/status/?apikey=$ZAP_API_KEY"
curl "http://localhost:$ZAP_PORT/HTML/core/view/alerts/?apikey=$ZAP_API_KEY"
curl "http://localhost:$ZAP_PORT/OTHER/core/other/htmlreport/?apikey=$ZAP_API_KEY&formMethod=GET" > ./$E2E_BASEDIR/$ZAP_HTML_OUTPUT_FOLDER/ZAP_Report.HTML

echo "Shutting down the ZAP Server"
curl -s "http://localhost:$ZAP_PORT/JSON/core/action/shutdown/?apikey=$ZAP_API_KEY"
echo "Finished!"
