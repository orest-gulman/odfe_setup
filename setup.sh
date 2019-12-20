#! /bin/bash
cyan='\033[0;36m'
green='\033[0;32m'
red='\033[0;31m'
nocol='\033[0m'

  distro=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')

if ! [ $distro == ubuntu ]
  then
   echo -e "${red}Script isn't compatible with current Linux distribution!...exit${nocol}"
   exit 1
  else
    continue
fi

echo -e "${cyan}Installing docker... ${nocol}"
sleep 3
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
sleep 1
  
echo -e "${cyan}Installing docker-compose... ${nocol}"
sleep 3
  apt install docker-compose -y
sleep 1
echo -e "${cyan}Installing apache2-utils... ${nocol}"
sleep 3
  apt install apache2-utils -y
sleep 1
echo -e "${cyan}Installing ruby... ${nocol}"
sleep 3
  apt install ruby -y
sleep 1

echo -e "${cyan}Enter admin user password...${nocol}"
  read -p ": " admin_pass
  
echo -e "${cyan}Enter elasticsearch user password...${nocol}"
  read -p ": " elasticsearch_pass

echo -e "${cyan}Generating bcrypt hash for admin user...${nocol}"
sleep 2
  admin_hash=$(htpasswd -bnBC 10 "" $admin_pass | tr -d ':\n')
echo $admin_hash

echo -e "${cyan}Generating bcrypt hash for elasticsearch user...${nocol}"
sleep 2
  elasticsearch_hash=$(htpasswd -bnBC 10 "" $elasticsearch_pass | tr -d ':\n')
echo $elasticsearch_hash

echo -e "${cyan}Generating password for kibanaserver user...${nocol}"
sleep 2
  kibanaserver_pass=$(openssl rand -base64 10)
echo $kibanaserver_pass
echo -e "${cyan}Generating bcrypt hash for kibanaserver user...${nocol}"
sleep 2
  kibanaserver_hash=$(htpasswd -bnBC 10 "" $kibanaserver_pass | tr -d ':\n')
echo $kibanaserver_hash
  
echo -e "${cyan}Applying configuration...${nocol}"
sleep 2
  ruby ./config.rb "$admin_hash" "$kibanaserver_hash" "$elasticsearch_hash" "$kibanaserver_pass"
echo -e "${cyan}internal_users.yml${nocol}"
  cat internal_users.yml
sleep 2
echo -e "${cyan}kibana.yml${nocol}"
  cat kibana.yml
sleep 2

echo -e "${cyan}Running elasticsearch and kibana containers...${nocol}"
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
    if ! [ ${code[1]} == '200' ]
      then
        echo "$response"
        sleep 10
    else
    #elif [ ${code[1]} == '200' ]
      #then
        echo "$response"
        echo -e "${cyan}Kibana is ready...${nocol}"
        sleep 2
        echo -e "${cyan}Importing saved data for winlogbeats...${nocol}"
        sleep 2
        curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@import-logs.ndjson -u admin:${admin_pass} -w "\n"
        echo -e "${cyan}Importing saved data for metricbeats...${nocol}"
        sleep 2
        curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@import-metrics.ndjson -u admin:${admin_pass} -w "\n"
        echo -e "${cyan}Importing Advanced Settings [7.3.2]...${nocol}"	
        sleep 2
        curl -X POST "localhost:5601/api/saved_objects/_resolve_import_errors" -H "kbn-xsrf: true" --form file=@import-settings.ndjson --form retries='[{"type":"config","id":"7.3.2","overwrite":true}]' -u admin:${admin_pass} -w "\n"
        break
    fi
done

if [ $n == 20 ]
  then
   echo -e "${red}Tries exceeded...exit${nocol}"
   docker logs odfe-node1 --tail 5
   exit 1
fi  
  
  valhost=$(hostname)
  ip=$(hostname -I | cut -d' ' -f1)

echo -e "${green}Kibana is running http://$valhost:5601${nocol}"
echo -e "${green}Elasticsearch is running http://$valhost:9200${nocol}"
echo -e "${cyan}admin user password: $admin_pass${nocol}"
echo -e "${cyan}kibanaserver user password: $kibanaserver_pass${nocol}"
echo -e "${cyan}elasticsearch user password: $elasticsearch_pass${nocol}"
echo -e "${cyan}Server IP address: $ip.${nocol}"
