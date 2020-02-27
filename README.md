# AutoSSH

> 通过 AutoSSH 建立反向连接

## 问题
通过外网访问局域网内的设备，局域网内设备的IP为内网IP，在外网下无法直接访问，如公司内部的GPU服务器，平时只能在公司的局域网环境下访问，但一旦离开公司的局域网环境，便无法连接到GPU服务器。而公网IP由于IPv4的原因，非常稀少，不可能为每一台设备都分配自己的公网IP。
为了能够访问到局域网中的设备，主要有两种方式：

> 端口映射：需要权限管理上级网关或者路由器或者防火墙<br>
> 反向连接：需要一台外网服务器（VPS）做中继主机<br>
> <br>
> Internet上去主动连接一台内网是不可能的，一般的解决方案分两种，一种是端口映射（Port Forwarding），将内网主机的某个端口Open出防火墙，相当于两个外网主机通信；另一种是内网主机主动连接到外网主机，又被称作反向连接（Reverse Connection），这样NAT路由/防火墙就会在内网主机和外网主机之间建立映射，自然可以相互通信了。但是，这种映射是NAT路由自动维持的，不会持续下去，如果连接断开或者网络不稳定都会导致通信失败，这时内网主机需要再次主动连接到外网主机，建立连接。

![](https://www.micronbot.com/usr/uploads/2016/07/3270104335.jpg)

## 解决思路

建立一个内网服务器到外网服务器的SSH隧道，使得其他设备可以通过中继主机访问内网设备。
SSH除了用以登录VPS外，还可以用来构建数据传输的隧道。我们可将VPS的某一个端口（A）通过SSH绑定到另一个端口（B），这样所有通过端口A的数据都会被传到端口B。这就为我们实现反向连接提供了方案：

首先将局域网内的服务器的某个端口映射到外网服务器的某个端口，这使得局域网内的服务器可以通过监听外网服务器上的某个端口，并将该端口上的数据全部传入自己的某个端口进行处理。
例如，我们想在外网环境下使用ssh访问内网中的GPU服务器，我们在GPU服务器上监听外网继中服务器的端口8504, 将集中服务器8504端口获得的所有数据交给自己的22端口处理，变相的实现了通过ssh访问内网的GPU服务器。这种通过内网GPU服务器连接外网集中服务器，反而却实现了外网设备访问内网的操作 就叫做 **反向连接**

内网GPU服务器监听外网继中服务器端口，可以在GPU服务器上执行
```
ssh -NfR 2333:localhost:5000 root@gaylun.space
```
相当于将GPU服务器的5000端口绑定到中继服务器gaylun.space的2333端口上，可以通过ss -ant在继中服务器上查看状态
```
ss -ant

State      Recv-Q Send-Q Local Address:Port               Peer Address:Port                              
LISTEN     0      128          *:2333                     *:*                  

```
但这种连接较不稳定，所以我们使用autossh建立一个守护进程。Autossh会在另一个端口上建立一个守护进程，监视ssh的连接，一旦断掉便进行重连。

## 具体操作
### Setp1
在内网服务器上创建密钥对,创建时可以指定密钥文件名，不建议设置密码，为空即可。
```
ssh-keygen
```
创建密钥的原因是我们将使用脚本自动通过ssh连接继中服务器，而连接时往往需要密码，为了避免手动输入密码，我们将在创建一对密钥用以直接访问。
### Step2
将生成的.pub文件里的内容复制到外网上的中继服务器服务器的~/.ssh/authorized_keys的尾部<br>
如果本地有多个密钥，则需要修改~/.ssh/config,添加如下信息，用以指定使用的密钥
```
Host <要访问的地址>
IdentityFile ~/.ssh/<私钥文件>
User <用户>

```

### Step3
创建tunel.sh文件（名字自定），内容如下
```

MORNITOR_PORT=12237
REMOTE_PORT=2333
SSH_HOST=gaylun.space
SSH_PORT=22
LOCAL_PORT=5000
autossh -M $MORNITOR_PORT -N \
        -f -o 'PubkeyAuthentication=yes' \
           -o 'PasswordAuthentication=no' \
           -o 'ServerAliveInterval 30' \
           -o 'ServerAliveCountMax 3' \
        -R $REMOTE_PORT:localhost:$LOCAL_PORT \
           root@$SSH_HOST -p $SSH_PORT &

```
执行 ./tunel.sh
+ MORNITOR_PORT=监视器的端口（自定义，用以守护ssh的连接）
+ REMOTE_PORT=被监听的端口（从被监听的端口获取数据，交给本地端口处理）
+ SSH_HOST=目标主机地址
+ SSH_PORT=目标主机ssh的端口（一般为22）
+ LOCAL_PORT=本地端口


### Step4
完成以上操作之后，只能在继中服务器上通过localhost访问本地被监听的端口（变相访问GPU服务器上的端口），为了使得我们可以通过外网上的任何一台设备访问继中器上的被监听端口，我们需要修改ssh的配置。<br>
**修改中继服务器的/etc/ssh/sshd_config**
```
GatewayPorts yes 

```
之后重启sshd
```
service sshd restart
```
