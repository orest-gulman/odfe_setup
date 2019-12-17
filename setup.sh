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

echo -e "${cyan}Enter admin password for elasticsearch and kibana ${nocol}"
read -p ": " admin_pass
  
#echo "${cyan}Running temp elasticsearch container for generating bcrypt hashes${nocol}"
#docker run -d --name hash  -e "ES_JAVA_OPTS=-Xms4096m -Xmx4096m" -e "discovery.type=single-node" amazon/opendistro-for-elasticsearch:1.2.1
#sleep 2
  
#hash=$(docker exec -it hash /bin/bash -c "chmod 755 plugins/opendistro_security/tools/hash.sh; plugins/opendistro_security/tools/hash.sh -p $admin_pass")
#echo "${cyan}Generated hash for admin password: $hash${nocol}"
#sleep 2
  
hash=$(htpasswd -bnBC 10 "" $admin_pass | tr -d ':\n')
echo -e "${cyan}Generated hash for admin password: $hash${nocol}"
  
#sed -i -e "s/replacehash/"$hash"/g" internal_users.yml
echo "  hash: "${hash}"" >> internal_users.yml
sleep 2
  
#echo "${cyan}Removing temporary elasticsearch container!${nocol}"
#docker rm hash -f
#sleep 2
  
echo -e "${cyan}Running elasticsearch and kibana containers${nocol}"
docker-compose up -d
  
echo -e "${cyan}Waiting 60sec...${nocol}"
sleep 60
docker ps

echo -e "${cyan}Checking elasticsearch and kibana containers status...${nocol}"
if [ $(docker inspect -f '{{.State.Running}}' odfe-node1) == true ] && [ $(docker inspect -f '{{.State.Running}}' odfe-kibana) == true ]
then
  echo -e "${cyan}Elasticsearch and kibana containers up...${nocol}"
else
 echo -e "${red}Docker containers are't running!...exit${nocol}"
 sleep 2
 exit 1
fi
  
valhost=$(hostname)
echo -e "${cyan}Kibana started http://$valhost:5601${nocol}"
echo -e "${cyan}Elasticsearch started http://$valhost:9200${nocol}"
echo -e "${cyan}admin password: $admin_pass${nocol}"

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
        echo -e "${cyan}Importing saved data for metricbeats...${nocol}"
        curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@import-metrics.ndjson -u admin:${admin_pass} -w "\n"
        #echo -e ${code[1]}
        break
    fi
done
  
#echo "${cyan}Importing savad data for metricbeats!${nocol}"
#curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@metrics.ndjson -u admin:${admin_pass} -w "\n"
