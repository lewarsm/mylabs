#!/bin/sh
apt install net-tools -y
apt install openjdk-11-jre-headless -y
mkdir /opt/lab
mkdir /opt/glauth
mv /tmp/pingfed* /opt/lab

mydir=labs-`echo $$`
CLEAR_PASS=2Federate
cd /tmp; mkdir $mydir; cd $mydir
git clone https://github.com/lewarsm/mylabs.git
wget https://github.com/glauth/glauth/releases/download/v2.3.2/glauth-linux-amd64 -P /opt/glauth/
chmod 755 /opt/glauth/glauth-linux*
mv /tmp/$mydir/mylabs/labskeys/gl* /opt/glauth
mv /tmp/$mydir/mylabs/labskeys/* /opt/lab
cat /opt/glauth/glauth.b64 | base64 -d > /opt/glauth/sample-simple.cfg

cp /opt/glauth/glauth.service /etc/systemd/system
chmod 755 /etc/systemd/system/glauth.service /opt/glauth/glauth.sh

chown -R cloud_user /opt/lab
chown -R cloud_user /opt/glauth


systemctl daemon-reload;systemctl start glauth
systemctl enable glauth

#prepare PingFederate
cd /opt/lab
cat newkey.txt | base64 -d > out; 7z e out -pD1rtyS3cret 2>&1 1>/dev/null
BASE64_LICENSE=`cat ./- | base64 -w 0`

unzip -q /tmp/pingfederate-12.1.3.zip -d /opt/lab
sed -i -e '2 r pfenv.txt' /opt/lab/pingfederate-12.1.3/pingfederate/bin/run.sh
sed -i -e 's/9031/8443/g' /opt/lab/pingfederate-12.1.3/pingfederate/bin/run.properties
sed -i -e 's/9999/9990/g' /opt/lab/pingfederate-12.1.3/pingfederate/bin/run.properties

nohup /opt/lab/pingfederate-12.1.3/pingfederate/bin/run.sh &


LOCAL_IP=$(route | grep default | awk '{print $8}' | xargs ifconfig | grep inet | grep -v inet6 | awk '{print $2}')
PF_ADMIN_PORT=9990
B64_ADMIN_PW=$(echo -n 'administrator:'2Federate'' | base64)

curl --insecure --ipv4 -X PUT \
  'https://localhost:9990/pf-admin-api/v1/license/agreement' \
  -H 'Content-Type: application/json' \
  -H 'X-XSRF-Header: PingFederate' \
  -H 'cache-control: no-cache' \
  -d '{
  "licenseAgreementUrl": "https://localhost:9990/pf/pf-admin-api/license-agreement",
  "accepted": true
}'
printf "\n"
printf "\n"



curl --insecure --ipv4 -X PUT \
  'https://localhost:9990/pf-admin-api/v1/license' \
  -H 'Content-Type: application/json' \
  -H 'X-XSRF-header: PingFederate' \
  -H 'cache-control: no-cache' \
  -d '{ "fileData": "'$BASE64_LICENSE'" }'
printf "\n"
printf "\n"
