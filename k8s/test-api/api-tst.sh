Bearer='TOKEN'


#DELETE RESOURCES
curl  -o /dev/null --insecure -XDELETE  -H "Authorization: Bearer $Bearer"  'https://ip:8443/api/v1/namespaces/default/pods/zabbix-tst'
curl -o /dev/null --insecure -XDELETE  -H "Authorization: Bearer $Bearer" 'https://ip:8443/api/v1/namespaces/default/services/zbx-service'
curl -o /dev/null --insecure -XDELETE  -H "Authorization: Bearer $Bearer" 'https://ip:8443/apis/extensions/v1beta1/namespaces/default/ingresses/zbx-ingress'


#CREATE RESOURCES
curl -s -o /dev/null --insecure -XPOST  -H "Authorization: Bearer $Bearer"  -H 'Content-Type: application/json' -d '{"apiVersion":"v1","kind":"Pod","metadata":{"name":"zabbix-tst","namespace":"default","labels":{"app":"zbx"}},"spec":{"containers":[{"name":"nginx","image":"nginx:1"}]}}' 'https://ip:8443/api/v1/namespaces/default/pods'


curl -s -o /dev/null --insecure -XPOST  -H "Authorization: Bearer $Bearer"  -H 'Content-Type: application/json' -d '{"apiVersion":"v1","kind":"Service","metadata":{"name":"zbx-service","namespace":"default","labels":{"app":"zbx"}},"spec":{"ports":[{"port":80,"targetPort":80}],"type":"ClusterIP","selector":{"app":"zbx"}}}' 'https://ip:8443/api/v1/namespaces/default/services'

curl -s -o /dev/null --insecure -XPOST  -H "Authorization: Bearer $Bearer"  -H 'Content-Type: application/json' -d '{"apiVersion":"extensions/v1beta1","kind":"Ingress","metadata":{"name":"zbx-ingress","namespace":"default"},"spec":{"rules":[{"host":"www.ngn.tst","http":{"paths":[{"backend":{"serviceName":"zbx-service","servicePort":80},"path":"/"}]}}]}}' 'https://ip:8443/apis/extensions/v1beta1/namespaces/default/ingresses'

#WAIT FOR SOME TIME
sleep 15;
curl -s -o /dev/null -w "%{http_code}" -L -H 'Host: www.ngn.tst' ingressip 
#20x - good
#40x- nevermind
#50x - REALLY BAD
