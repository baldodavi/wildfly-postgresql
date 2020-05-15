TAG=0.9.14
NAME=redeccg-production-wildfly-db-drivers-debian
docker build -f $NAME.dockerfile -t $NAME:$TAG .
docker tag $NAME:$TAG david-baldo.com/$NAME:$TAG
docker push david-baldo.com/$NAME:$TAG
