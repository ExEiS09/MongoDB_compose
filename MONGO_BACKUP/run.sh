#!/bin/sh

if [[ -z $CLUSTER ]]
    then
        echo 'Please specify the cluster node with CLUSTER environment variable, with comma-separated values'
        exit 1
fi

if [[ -z $ADMIN_NAME || -z $ADMIN_PASSWD ]]
    then
        echo 'Please specify the admin name with ADMIN_NAME and admin password with ADMIN_PASSWD environment variables from the target CLUSTER'
        exit 2
fi

### Remember that we can use any directory for MongoDB Master instance with BASE_DIRECTORY environment variable. But by default it would be the default paths in SM installations: /media/data/mongodb/mongodb
if [[ -z $BASE_DIRECTORY ]]
    then
        BASE_DIRECTORY="/media/data/mongodb/mongodb"
fi


### Variables Section
CONTAINER_BASE_DIR="/media/data/mongodb/backups"
LOCKER_ZAGLUSHKA=$(echo 'db.fsyncLock()' > /tmp/locker.js)
CHECK_LOCK=$(echo 'db.currentOp().fsyncLock' > /tmp/checklock.js)
UNLOCKER_ZAGLUSHKA=$(echo 'db.fsyncUnlock()' > /tmp/unlock.js)
MASTER_ZAGLUSHKA=$(echo 'db.isMaster().secondary' > /tmp/master.js)
MASTER_CHECK=$(mongo --host "$i:${PORT}" -u ${ADMIN_NAME} -p ${ADMIN_PASSWD} < /tmp/master.js | grep true)
PORT=27017
DEADINT=86400
###


while true
    do
    ### Let's initialize the backup archive name with timestamps!
        timestamp=date +%d%m%y
        backup="${CONTAINER_BASE_DIR}/${timestamp}"
    ### Now we need to understand, which node is master, because we need to lock all replica nodes BEFORE backup (thnx, 4.4)
        for i in $(echo $CLUSTER | sed "s/,/ /g")
            do
                ${MASTER_CHECK}
                if [[ $(echo $?) -ne 0 ]]
                    then
                        LOCK=$(mongo --host "$i:${PORT}" -u ${ADMIN_NAME} -p ${ADMIN_PASSWD} < /tmp/locker.js)
                        CHECK_LOCK=$(mongo --host "$i:${PORT}" -u ${ADMIN_NAME} -p ${ADMIN_PASSWD} < /tmp/checklock.js | grep true)
                        if [[ $(echo $?) -ne 0 ]]
                            then
                                echo 'Cannot LOCK the secondary nodes. Please verify that cluster is alive or try later'
                                exit 4
                            else
                                rsync -avz -e ssh ${SYNC_USER}@$i:/${BASE_DIRECTORY} $backup && tar -czvf ${i}-backup-${timestamp}.tar.gz ${backup} && rm -f ${backup}
                                if [[ $(echo $?) -eq 0 ]]
                                    then
                                        echo 'Backup Succeed'
                                else
                                        echo 'Cannot backup files properly. Verify the connection with master node'
                                        exit 5
                                fi
                        fi
                fi
            done
    ### And now we need to unlock the secondary replicaSet nodes for continue working
        for i in $(echo ${CLUSTER} | sed "s/,/ /g")
            do
                ${MASTER_CHECK}
                if [[ $echo $? -ne 0 ]]
                    then
                        UNLOCK=$(mongo --host "$i:${PORT}" -u ${ADMIN_NAME} -p ${ADMIN_PASSWD} < /tmp/unlock.js)
                        CHECK_UNLOCK=$(mongo --host "$i:${PORT}" -u ${ADMIN_NAME} -p ${ADMIN_PASSWD} < /tmp/checklock.js | grep bye)
                        if [[ $(echo $?) -ne 0 ]]
                            then
                                echo 'BackUp succesfully stored. But Base cannot Unlock Properly. Please, unlock DataBase manually.'
                            else
                                echo 'BackUp succesfully stored. Database ready for production.'
                        fi
                fi
            done
    ### And going to sleep interval (24 hrs)
        if [[ ${DEADINT} -gt 0 ]]
            then
                sleep ${DEADINT}
            else
                break
        fi
done