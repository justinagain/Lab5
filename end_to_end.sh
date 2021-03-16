echo start the ZAP in daemon mode
nohup /Applications/OWASP\ ZAP.app/Contents/MacOS/ZAP.sh -daemon &
echo "Sleep for 20 seconds to make sure its initialized!"
sleep 20

echo "Get the status of ZAP"
CURL "http://localhost:8090"

echo "Spider scan for the web site"
CURL "http://localhost:8090/JSON/spider/action/scan/?zapapiformat=JSON&formMethod=GET&url=http://hackazon.webscantest.com"
echo "Wait for 20 sec to complete the Scan before moving to Active scan"
sleep 20

echo "Active Scan for the website"
CURL "http://localhost:8090/JSON/ascan/action/scan/?zapapiformat=JSON&formMethod=GET&url=http://hackazon.webscantest.com&recurse=&inScopeOnly=&scanPolicyName=&method=&postData=&contextId="
echo "Wait for 20 sec to complete the ActiveScan before generating the testing report"
sleep 20

echo "List the security assessments results (alerts), and output the report to ZAP_Report.HTML"
CURL "http://localhost:8090/JSON/ascan/view/status/"
CURL "http://localhost:8090/HTML/core/view/alerts/"
CURL "http://127.0.0.1:8090/OTHER/core/other/htmlreport/?formMethod=GET" > ZAP_Report.HTML

echo "shutdown the ZAP"
curl -s "http://localhost:8090/JSON/core/action/shutdown/?apikey=12345"
echo "finished!"
