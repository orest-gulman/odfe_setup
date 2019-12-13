#! /bin/bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  
  apt-get install docker-compose -y

  read -p "Enter kibana admin password: " kibana_pass
  read -p "Enter elasticseach admin password: " elasticseach_pass

  echo $kibana_pass
  echo $elasticseach_pass
