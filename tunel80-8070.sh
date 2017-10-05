MORNITOR_PORT=25677
REMOTE_PORT=8070
SSH_HOST=gaylun.space
SSH_PORT=22
LOCAL_PORT=14258
autossh -M $MORNITOR_PORT -N \
        -f -o 'PubkeyAuthentication=yes' \
           -o 'PasswordAuthentication=no' \
           -o 'ServerAliveInterval 30' \
           -o 'ServerAliveCountMax 3' \
        -R $REMOTE_PORT:localhost:$LOCAL_PORT \
           root@$SSH_HOST -p $SSH_PORT &
