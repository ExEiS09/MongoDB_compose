#!/bin/bash

if [[ -z "$CLUSTER" ]]
  then
  echo "Please enter the cluster node names with comma-separated key-value"
  exit 1
fi

if [[ -z "$ADMIN_NAME" || -z "$ADMIN_PASS" ]]
  then
  echo 'Specify the init administrator DB and password with ADMIN_NAME and ADMIN_PASS'
  exit 2
fi

if [[ -z "$RS_NAME" ]]
  then
  echo 'Specify the replicaset RS_NAME!'
  exit 3
fi

if [[ -z "$BASE_NAME" || -z "$BASE_USER" || -z "$BASE_PASSWORD" ]]
  then
  echo 'Specify the base name, base user and base password with BASE_NAME BASE_USER and BASE_PASSWORD'
  exit 4
fi

if [[ -z "$CONTAINER_NAME" ]]
  then
  echo 'Specify the CONTAINER_NAME as environment variable'
  exit 5
fi

pstst=$BASE_PASSWORD
psw=$ADMIN_PASS

sed -i "s/rs0/$RS_NAME/g" /etc/mongo/mongod.conf

#### Create admin user through mongo <
admincreate=$(cat <<EOF
db.createUser(
  {
    user: "$ADMIN_NAME",
    pwd: "$ADMIN_PASS",
    roles: [
       { role: "root", db: "admin" }
    ]
  }
)
EOF
)


### Create base user through mongo <
usercreate=$(cat <<EOF
db.createUser(
  {
    user: "$BASE_USER",
    pwd: "$BASE_PASSWORD",
    roles: [
       { role: "readWrite", db: "$BASE_NAME" },
       { role: "read", db: "reporting" }
    ]
  }
)
EOF
)

CONTAINER_BASE_DIR="/media/data/mongodb"

if [ -z "$LOG_DIR" ]; then
	LOG_DIR=${CONTAINER_BASE_DIR}/logs
fi

if [ -z "$DATA_DIR" ]; then
    DATA_DIR=${CONTAINER_BASE_DIR}/mongodb
fi

export LOG_DIR
export DATA_DIR

# Log dir create if not exist
[ ! -d "$LOG_DIR" ] && mkdir -p $LOG_DIR 
# Data dir create if not exist
[ ! -d "$DATA_DIR" ] && mkdir -p $DATA_DIR 

### Initialize non-secured cluster
/usr/bin/mongod --dbpath $DATA_DIR --logpath $LOG_DIR/mongo.log --pidfilepath /tmp/mongo.pid --bind_ip 0.0.0.0 --fork
rootdb='admin'
userdb=$BASE_NAME
echo $admincreate > admin.js
echo $usercreate > user.js
mongo $rootdb < admin.js
echo 'use $BASE_NAME' > db.js
mongo < db.js
mongo $userdb < user.js
pkill mongod

### We need this, 'cause not all instances can be up and running in 10 seconds :(
sleep 30


### Initialize secured cluster...
/usr/bin/mongod --config /etc/mongo/mongod.conf --fork
sleep 30

### Initialize ReplicaSet

### We need this section because we need to initiate replica set only on ONE node. And we need the environment variable that contain ankor for choosing the only one master.

if [[ $(echo $CONTAINER_NAME) == *'1'*  ]] || [[ $(echo $CONTAINER_NAME) == *'master'* ]]
  then
    mongo admin -u ${ADMIN_NAME} -p ${ADMIN_PASS} --eval "rs.initiate()"
fi

for i in $(echo "${CLUSTER[@]}" | sed "s/,/ /g")
  do
    mongo admin -u ${ADMIN_NAME} -p ${ADMIN_PASS} --eval "rs.slaveOk()"
    mongo admin -u ${ADMIN_NAME} -p ${ADMIN_PASS} --eval "rs.add( { host: \"${i}:27017\" } )" 
    #, priority: 0, votes: 0 
  done

### Delete all init JS....
rm -rf user.js admin.js db.js

### Klling instance one more time with sleep...
pkill mongod
sleep 30

### And finally start with initiated cluster and RS, in theory...
sed -i '/processManagement/d' /etc/mongo/mongod.conf
sed -i '/fork/d' /etc/mongo/mongod.conf
sed -i '/pidFilePath/d' /etc/mongo/mongod.conf
/usr/bin/mongod --config /etc/mongo/mongod.conf
