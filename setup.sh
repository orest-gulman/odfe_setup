#! /bin/bash
  col='\033[0;36m' # Cyan
  nocol='\033[0m' # No Color
  
  echo -e "${col}Installing docker... ${nocol}"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sleep 2
  
  echo -e "${col}Installing docker-compose... ${nocol}"
  apt-get install docker-compose -y
  sleep 2

  echo -e "${col}Enter admin password for elasticsearch and kibana ${nocol}"
  read -p ": " admin_pass
  
  echo - e "${col}Running temp elasticsearch container for generating bcrypt hashes${nocol}"
  docker run -d --name hash  -e "ES_JAVA_OPTS=-Xms4096m -Xmx4096m" -e "discovery.type=single-node" amazon/opendistro-for-elasticsearch:1.2.1
  sleep 10
  
  hash=$(docker exec -it hash /bin/bash -c "chmod 755 plugins/opendistro_security/tools/hash.sh; plugins/opendistro_security/tools/hash.sh -p $admin_pass")
  echo -e "${col}Generated hash for admin password: $hash${nocol}"
  sleep 2
  
  sed -i -e "s/replacehash/$hash/g" internal_users.yml
  sleep 2
  
  echo -e "${col}Removing temporary elasticsearch container!${nocol}"
  docker rm hash -f
  sleep 2
  
  echo -e "${col}Running elasticsearch and kibana containers${nocol}"
  docker-compose up -d
  sleep 2
  
  docker ps
  valhost=$(hostname)
  echo -e "${col}kibana is running http://$valhost:5601${nocol}"
  echo -e "${col}elasticsearch is running http://$valhost:9200${nocol}"
  echo -e "${col}admin password: $admin_pass${nocol}"
  echo -e "${col}Now waiting...${nocol}"
