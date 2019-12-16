#! /bin/bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  
  apt-get install docker-compose -y
  sleep 2
  read -p "Enter admin password for kibana and elasticsearch: " admin_pass
  echo "running temporary elasticsearch container for generating bcrypt hashes"
  docker run -d --name hash  -e "ES_JAVA_OPTS=-Xms4096m -Xmx4096m" -e "discovery.type=single-node" amazon/opendistro-for-elasticsearch:1.2.1
  echo "waiting 10sec for elasticsearch up and running!"
  sleep 10
  hash=$(docker exec -it hash /bin/bash -c "chmod 755 plugins/opendistro_security/tools/hash.sh; plugins/opendistro_security/tools/hash.sh -p $admin_pass")
  echo "generated hash: $hash"
  sleep 2
  sed -i -e "s/replacehash/$hash/g" internal_users.yml
  sleep 2
  echo "remove temporary elasticsearch container!"
  docker rm hash -f
  sleep 2
  echo "running pre-configuresd elasticsearch and kibana containers"
  docker-compose up -d
  sleep 2
  docker ps
  valhost=$(hostname)
  echo "kibana is running http://$valhost:5601"
  echo "elasticsearch is running http://$valhost:9200"
  echo "admin password: $admin_pass"
  #docker exec -it odfe-node1 /bin/bash -c "cd plugins/opendistro_security/tools/; ./securityadmin.sh -cd ../securityconfig/ -icl -nhnv -cacert /usr/share/elasticsearch/config/root-ca.pem -cert /usr/share/elasticsearch/config/kirk.pem -key /usr/share/elasticsearch/config/kirk-key.pem"
