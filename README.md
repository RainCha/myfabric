## 使用 Docker 单机部署 Fabric 网络

基于 fabric 1.2 版本

> 参考资料：
> - 《区块链原理设计与应用》第 9 章
> - https://hyperledger-fabric.readthedocs.io/en/latest/build_network.html

要部署并启动的 Fabric 网络中,包括一个 Orderer 节点和四个 Peer 节点，以及一个管理节点生成相关启动文件，在网络启动后作为操作客户端执行命令。
四个 Peer 节点分属于同一个管理域（example.com）下的两个组织 Org1 和 Org2，这两个组织都加入同一个应用通道（businesschannel）中。

每个组织中的第一个节点（peer0 节点）作为锚节点与其他组织进行通信，所有节点通过域名都可以相互访问，整体网络拓扑如图:
![图1](https://cdn-pri.nlark.com/yuque/0/2018/png/106116/1540637098408-fa016ecb-1ee7-472e-90ed-bc197539198d.png)

# 新建项目目录

```bash
mkdir myfabric
```

# 第 1 步：生成组织关系和身份证书

这一步要生成组织和节点的公私钥证书。

## 准备配置文件

配置文件 [myfabric/crypto-config.yaml](./crypto-config.yaml)：

## 执行命令

在 myfabric 目录下执行命令

```bash
cryptogen generate --config=./crypto-config.yaml --output crypto-config
```

会在 myfabric 目录中生成 crypto-config 文件夹。

# 第 2 步：准备相关配置文件

## 2.1 生成 Orderer 服务启动初始块

Orderer 节点在启动时，可以指定使用提前生成的初始区块文件作为系统通道的初始配置。初始区块中包括了 Ordering 服务的相关配置信息以及联盟信息。

### 准备配置文件

配置文件 [myfabric/configtx.yaml](./configtx.yaml)

### 执行命令

执行命令

```bash
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./orderer.genesis.block
```

此命令会在 myfabric 目录下生成 orderer 服务系统通道的初始块文件./orderer.genesis.block，将会在之后的启动 Orderering 服务时使用。

## 2.2 生成通道配置文件

新建应用通道时，需要事先准备好配置交易文件，其中包括属于该通道的组织结构信息。这些信息会写入该应用通道(businesschannel)的初始区块中。
生成通道配置文件也会使用 2.1 的配置文件 configtx.yaml 。

#### 执行命令

设置环境变量指定应用通道名称，为了后续使用(此环境变量只是临时的，一旦切换终端窗口，需要重新设置)

```bash
CHANNEL_NAME=businesschannel
```

执行命令

```bash
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./businesschannel.tx -channelID ${CHANNEL_NAME}
```

此命令会在 myfabric 目录下生成配置交易文件 businesschannel.tx，将会在之后的客户端节点中使用。

## 2.3 生成锚节点配置更新文件

锚节点配置更新文件可以用来对组织的锚节点进行配置。同样基于 2.1 的 configtx.yaml 配置文件。

### 为组织 1 生成

```bash
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID ${CHANNEL_NAME}  -asOrg Org1MSP
```

### 为组织 2 生成

```bash
 configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org2MSPanchors.tx -channelID ${CHANNEL_NAME}  -asOrg Org2MSP
```

上述命令会在 myfabric 目录下生成两个组织的锚节点配置更新文件 Org1MSPanchors.tx、Org2MSPanchors.tx。会在后续被客户端节点使用。

# 第 3 步：启动 Docker 网络

## 3.0 整理文件

目前 myfabric 目录，文件有点多，现在整理成如下图：
![图2](https://cdn-pri.nlark.com/yuque/0/2018/png/106116/1540640004095-7726c8e3-cf84-4dc7-b446-6d4afefb83a5.png)
就是新创建了一个 channel-artifacts 目录，并把# 第 2 步生成的配置文件放进去。

## 3.1 准备 docker-compose-cli.yaml 文件

文件[myfabric/docker-compose-cli.yaml](./docker-compose-cli.yaml)

## 3.2 准备链码 example.go

新建 [myfabric/chaincode/example.go](./chaincode/example.go) 文件作为链码文件

## 3.2 启动网络

在启动之前，如果之前启动过这个容器，很可能有残留文件，导致后续操作不成功，这里先清除下已经退出的容器：

```bash
docker rm $(docker ps -q -f status=exited)
```

执行命令

```bash
docker-compose -f ./docker-compose-cli.yaml up
```

# 第 4 步：操作网络

操作网络的行为都是发生在客户端节点，因此需要进入客户端节点中，这里指的就是 cli 容器。执行下面，命令进入容器：

```
docker exec -it cli /bin/bash
```

以下操作都发生在 cli 容器中。

## 4.1 创建通道

网络启动后，默认并不存在任何应用通道，需要手动创建应用通道，并让合作的 Peer 节点加入通道中。

### 1 配置通用环境变量

首先，配置一些接下来要持续使用的通用环境变量。

```bash
CHANNEL_NAME -- 应用通道名称
ORDERER_CA -- Orderering服务的tls证书位置
CHANNEL_NAME=businesschannel
ORDERER_CA=/etc/hyperledger/fabric/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

### 2 执行命令

使用加入联盟中的组织管理员身份（这里我们 Org1 的管理员身份，当然也可以是 Org2 的管理员身份）可以创建应用通道。

在客户端中使用 Org1 的管理员身份来创建应用通道，需要指定管理员身份信息：

- msp 的 ID 信息 -- CORE_PEER_LOCALMSPID
- msp 文件所在路径 -- CORE_PEER_MSPCONFIGPATH
- 连接 orderer 服务的 TLS 配置 -- CORE_PEER_TLS_ROOTCERT_FILE (如果在启动 orderer 容器时，设置了 CORE_PEER_TLS_ENABLED=true ，就需要指定 CORE_PEER_TLS_ROOTCERT_FILE 环境变量)
- peer 节点地址 -- CORE_PEER_ADDRESS

使用管理员身份来创建通道

```bash
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f ./channel-artifacts/businesschannel.tx --tls --cafile ${ORDERER_CA}
```

创建通道成功后，会自动在本地生成该应用通道同名的初始区块 businesschannel.block 文件。只有拥有该文件才可以加入创建的应用通道中。

## 4.2 把组织加入通道

在客户端使用组织管理员身份依次让组织 Org1 和 Org2 中的所有节点都加入新的应用通道，需要指定所操作的 Peer 的地址，以及通道的初始区块。

由于之前(docker-compose 配置文件中)设置了 CORE_PEER_TLS_ENABLED=true 所以还需要指定环境变量 CORE_PEER_TLS_ROOTCERT_FILE。

### 把组织 1 的 peer0 节点加入通道

```bash
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel join  -b ${CHANNEL_NAME}.block
```

### 把组织 1 的 peer1 节点加入通道

```bash
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer1.org1.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt

peer channel join  -b ${CHANNEL_NAME}.block
```

### 把组织 2 的 pee0 节点加入通道

```bash
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

peer channel join  -b ${CHANNEL_NAME}.block
```

### 把组织 2 的 pee1 节点加入通道

```bash
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer1.org2.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt

peer channel join  -b ${CHANNEL_NAME}.block
```

> 提示：在操作过程中，发现同属于一个组织的节点，可以使用同一个 CORE_PEER_TLS_ROOTCERT_FILE 文件

## 4.3 更新锚节点配置

锚节点负责代表组织与其他组织中的节点进行 Gossip 通信。
使用提前生成的锚节点配置更新文件（Org1MSPanchors.tx、Org2MSPanchors.tx），组织管理员身份可以更新指定应用通道中组织的锚节点配置。

这里在客户端使用了 Org1 的管理员身份来更新锚节点配置，需要指定：

- msp 的 ID 信息 -- CORE_PEER_LOCALMSPID
- msp 文件所在路径 -- CORE_PEER_MSPCONFIGPATH
- Ordering 服务地址 -- orderer.example.com:7050
- 所操作的应用通道 -- ${CHANNEL_NAME}
- 锚节点配置更新文件 -- ./channel-artifacts/Org1MSPanchors.tx
- Orderering 服务的 ca 文件 -- ${ORDERER_CA}

### 更新组织 1 的锚节点配置

```bash
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel update  -o orderer.example.com:7050  -c ${CHANNEL_NAME}  -f ./channel-artifacts/Org1MSPanchors.tx   --tls --cafile ${ORDERER_CA}
```

### 更新组织 2 的锚节点配置

```bash
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

peer channel update  -o orderer.example.com:7050  -c ${CHANNEL_NAME}  -f ./channel-artifacts/Org2MSPanchors.tx   --tls --cafile ${ORDERER_CA}
```

# 第 5 步：测试链码

链码被部署在 Fabric 网络节点上，运行在隔离沙盒（目前为 Docker 容器）中，并通过 gRPC 协议与相应的 Peer 节点进行交互，以操作分布式账本中的数据。
启动 Fabric 网络后，可以通过命令行或 SDK 进行链码操作，验证网络运行是否正常。这里使用的是命令行。

之前已转备好了链码文件 myfabric/chaincode/go/example.go ，绑定在了 cli 容器中的 /opt/gopath/src/github.com/hyperledger/fabric/myfabric/chaincode/go 目录下。链码已经准备好，接下来就开始安装。

节点加入应用通道后，可以执行链码相关操作，进行测试。链码在调用之前，必须先经过安装和实例化两个步骤，部署到 Peer 节点上。

> 注意：链码时按需安装，节点之间可以安装相同的一个链码，也可以是不同的。当节点需要安装一个链码时，此链码就可以只安装在这个节点上，其他节点不需要，就不用安装。
> 这里为了验证 myfabric 网络，因此只需要安装在一个节点上进行测试。之所以列出多个节点的安装步骤，是为了说明安装链码需要使用到的环境变量。

## 部署链码到 peer0.org1 节点上

首先配置环境变量，确保执行链码的权限。这里配置为 peer0.org1

```bash
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
```

### 1 安装链码

将示例链码 chaincode/go/example.go 到 Org1 的 Peer0 上：

```bash
peer chaincode install  -n test_cc  -v 1.0  -p github.com/hyperledger/fabric/myfabric/chaincode/go
```

> 注意： -p 对应的值是包含链码的的文件夹，而不是链码文件

### 2 实例化链码

通过如下命令将链码容器实例化，并注意通过-P 指定背书策略。
此处 OR（'Org1MSP.member'，'Org2MSP.member'）代表 Org1 或 Org2 的任意成员签名的交易即可调用该链码.

```bash
peer chaincode instantiate  -o orderer.example.com:7050   -C ${CHANNEL_NAME}   -n test_cc  -v 1.0  -c '{"Args":["init","a","100","b","200"]}'   -P "OR ('Org1MSP.member','Org2MSP.member')"    --tls   --cafile ${ORDERER_CA}
```

上面命令在账本上初始化了 a 的余额为 100 ，b 的余额为 200。

### 3 调用链码 -- (invoke 和 query)

实例化完成后，用户即可向网络中发起交易了。
首先，我们查一下初始化后的 a 的 余额，不出意外应该输出 100.

```bash
peer chaincode query   -n test_cc   -C ${CHANNEL_NAME}  -c '{"Args":["query","a"]}'
```

接下来，调用链码进行转账操作，从 a 中转出 10 给 b ：

```bash
peer chaincode invoke   -o orderer.example.com:7050     -C ${CHANNEL_NAME}    -n test_cc     -c '{"Args":["invoke","a","b","10"]}'    --tls   --cafile ${ORDERER_CA}
```

再查一下转账后的 a 的余额, 猜测应该为 90：

```bash
peer chaincode query   -n test_cc   -C ${CHANNEL_NAME}  -c '{"Args":["query","a"]}'
```

## 部署链码到 peer1.org2 节点上

> 注意：如果是把同一链码安装在同一网络中的节点上，则只需要在网络中第一次安装的时候进行实例化，之后的节点只需要进行安装即可。如果是不同链码，就需要在安装后，再进行实例化。

首先配置环境变量，确保执行链码的权限。这里配置为 peer1.org2

```bash
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer1.org2.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt
```

### 1 安装链码

```
peer chaincode install  -n test_cc  -v 1.0  -p github.com/hyperledger/fabric/myfabric/chaincode/go
```

### 2 实例化链码

这里要安装的是同一链码，就不进行实例化操作了。

### 3 调用链码

> 注意，由于这个网络中已经实例化过此链码，所以接下来的链码调用，系统会自动启动链码的 Docker 镜像。
> 调用链码，查询 b 的 余额。

```bash
peer chaincode query   -n test_cc   -C ${CHANNEL_NAME}  -c '{"Args":["query","b"]}'
```

调用链码，b 给 a 转账 30：

```
peer chaincode invoke   -o orderer.example.com:7050     -C ${CHANNEL_NAME}    -n test_cc     -c '{"Args":["invoke","b","a","30"]}'    --tls   --cafile ${ORDERER_CA}
```

再次查询 a 的余额。之前 a 是 90 ，转账后，应该为 120。

```bash
peer chaincode query   -n test_cc   -C ${CHANNEL_NAME}  -c '{"Args":["query","a"]}'
```
