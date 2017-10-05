MORNITOR_PORT=5974
REMOTE_PORT=4795
SSH_HOST=47.95.9.69
SSH_PORT=22
LOCAL_PORT=22
autossh -M $MORNITOR_PORT -N \
        -f -o 'PubkeyAuthentication=yes' \
           -o 'PasswordAuthentication=no' \
           -o 'ServerAliveInterval 30' \
           -o 'ServerAliveCountMax 3' \
        -R $REMOTE_PORT:localhost:$LOCAL_PORT \
           root@$SSH_HOST -p $SSH_PORT &
