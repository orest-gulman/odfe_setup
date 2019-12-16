#! /bin/bash
  col='\033[0;36m' # Cyan
  nocol='\033[0m' # No Color
  
  echo "${col}Installing docker... ${nocol}"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sleep 2
  
  echo "${col}Installing docker-compose... ${nocol}"
  apt-get install docker-compose -y
  sleep 2

  echo "${col}Enter admin password for elasticsearch and kibana ${nocol}"
  read -p ": " admin_pass
  
  echo "${col}Running temp elasticsearch container for generating bcrypt hashes${nocol}"
  docker run -d --name hash  -e "ES_JAVA_OPTS=-Xms4096m -Xmx4096m" -e "discovery.type=single-node" amazon/opendistro-for-elasticsearch:1.2.1
  sleep 2
  
  hash=$(docker exec -it hash /bin/bash -c "chmod 755 plugins/opendistro_security/tools/hash.sh; plugins/opendistro_security/tools/hash.sh -p $admin_pass")
  echo "${col}Generated hash for admin password: $hash${nocol}"
  sleep 2
  
  #sed -i -e "s/replacehash/"$hash"/g" internal_users.yml
  echo "  hash: "${hash}"" >> internal_users.yml
  sleep 2
  
  echo "${col}Removing temporary elasticsearch container!${nocol}"
  docker rm hash -f
  sleep 2
  
  echo "${col}Running elasticsearch and kibana containers${nocol}"
  docker-compose up -d
  sleep 2
  
  docker ps
  valhost=$(hostname)
  echo "${col}Kibana is running http://$valhost:5601${nocol}"
  echo "${col}Elasticsearch is running http://$valhost:9200${nocol}"
  echo "${col}admin password: $admin_pass${nocol}"
  
  echo "${col}Waitiong for elasticsearch and kibana up and running!${nocol}"
  sleep 120
  echo "${col}Importing savad data for metricbeats!${nocol}"
  curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@metrics.ndjson -u admin:${admin_pass}
