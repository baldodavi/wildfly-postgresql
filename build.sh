env TAG = 0.9.13
docker build -f redeccg-production-wildfly-db-drivers.dockerfile -t redeccg-production-wildfly-db-drivers:$TAG .
docker tag redeccg-production-wildfly-db-drivers:$TAG