TAG=0.9.14
docker build -f redeccg-production-wildfly-db-drivers.dockerfile -t redeccg-production-wildfly-db-drivers:$TAG .
docker tag redeccg-production-wildfly-db-drivers:$TAG david-baldo.com/redeccg-production-wildfly-db-drivers:$TAG
docker push david-baldo.com/redeccg-production-wildfly-db-drivers:$TAG
