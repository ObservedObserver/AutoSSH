MORNITOR_PORT=9984
REMOTE_PORT=6006
SSH_HOST=47.95.9.69
SSH_PORT=22
LOCAL_PORT=6006
autossh -M $MORNITOR_PORT -N \
        -f -o 'PubkeyAuthentication=yes' \
           -o 'PasswordAuthentication=no' \
           -o 'ServerAliveInterval 30' \
           -o 'ServerAliveCountMax 3' \
        -R $REMOTE_PORT:localhost:$LOCAL_PORT \
           root@$SSH_HOST -p $SSH_PORT &
