#! /bin/bash
cyan='\033[0;36m'
red='\033[0;31m'
nocol='\033[0m'
  
echo -e "${cyan}Installing docker... ${nocol}"
sleep 2
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sleep 1
  
echo -e "${cyan}Installing docker-compose... ${nocol}"
sleep 2
apt install docker-compose -y
sleep 1
echo -e "${cyan}Installing apache2-utils... ${nocol}"
sleep 2
apt install apache2-utils -y
sleep 1
echo -e "${cyan}Installing ruby... ${nocol}"
sleep 2
apt install ruby -y
sleep 1

echo -e "${cyan}Enter admin password for elasticsearch and kibana ${nocol}"
read -p ": " admin_pass

echo -e "${cyan}Generating bcrypt hash for admin user...${nocol}"
sleep 2
admin_hash=$(htpasswd -bnBC 10 "" $admin_pass | tr -d ':\n')
echo $admin_hash

echo -e "${cyan}Generating password for kibanaserver user...${nocol}"
sleep 2
kibanaserver_pass=$(openssl rand -base64 10)
echo $kibanaserver_pass
sed -i -e "s/kibanaserver_pass/"$kibanaserver_pass"/g" custom-kibana.yml
echo -e "${cyan}Generating bcrypt hash for kibanaserver user...${nocol}"
sleep 2
kibanaserver_hash=$(htpasswd -bnBC 10 "" $kibanaserver_pass | tr -d ':\n')
echo $kibanaserver_hash
  
#sed -i -e "s/replacehash/"$hash"/g" internal_users.yml
#echo "  hash: "${admin_hash}"" >> internal_users.yml
#sleep 2

ruby ./hashes.rb "$admin_hash" "$kibanaserver_hash"
  
echo -e "${cyan}Running elasticsearch and kibana containers${nocol}"
sleep 2
docker-compose up -d
  
echo -e "${cyan}Waiting 90sec...${nocol}"
sleep 90

echo -e "${cyan}Checking elasticsearch and kibana containers status...${nocol}"
sleep 2
if [ $(docker inspect -f '{{.State.Running}}' odfe-node1) == true ] && [ $(docker inspect -f '{{.State.Running}}' odfe-kibana) == true ]
then
  echo -e "${cyan}Elasticsearch and kibana containers up...${nocol}"
  docker ps
  sleep 2
else
 echo -e "${red}Docker containers are't running!...exit${nocol}"
 exit 1
fi

echo -e "${cyan}Checking kibana ready status...${nocol}"
sleep 2

for ((n=0;n<20;n++))
    do
    response=$(curl -s -XGET http://localhost:5601/status -I -u admin:$admin_pass|grep "HTTP/1.1")
    code=($response)
    if ! [ ${code[1]} == 200 ]
    then
        echo $response
        sleep 10
    else
        echo -e "${cyan}Kibana up...${nocol}"
        sleep 2
        #echo -e "${cyan}Importing saved data for winlogbeats...${nocol}"
        #sleep 2
        #curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@import-logs.ndjson -u admin:${admin_pass} -w "\n"
        echo -e "${cyan}Importing saved data for metricbeats...${nocol}"
        sleep 2
        curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@import-metrics.ndjson -u admin:${admin_pass} -w "\n"
        echo -e "${cyan}Importing Advanced Settings [7.2.1]...${nocol}"	
        sleep 2
        curl -X POST "localhost:5601/api/saved_objects/_resolve_import_errors" -H "kbn-xsrf: true" --form file=@import-settings-7.3.2.ndjson --form retries='[{"type":"config","id":"7.3.2","overwrite":true}]' -u admin:${admin_pass} -w "\n"
        #echo -e ${code[1]}
        break
    fi
done
  
valhost=$(hostname)
echo -e "${cyan}Kibana is running http://$valhost:5601${nocol}"
echo -e "${cyan}Elasticsearch is running http://$valhost:9200${nocol}"
echo -e "${cyan}admin user password: $admin_pass${nocol}"
echo -e "${cyan}kibanaserver user password: $kibanaserver_pass${nocol}"
#clear

#echo "${cyan}Importing savad data for metricbeats!${nocol}"
#curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@metrics.ndjson -u admin:${admin_pass} -w "\n"
