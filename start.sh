 
#### 定义通用变量
## 通道名称
CHANNEL_NAME=businesschannel
## 客户端节点composer配置文件
COMPOSE_FILE=docker-compose-cli.yaml
## 项目名称
PROJECT_NAME=myfabric



# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.test_cc.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# 替换重新ca中生成的私钥
function replacePrivateKey() {

  cp docker-compose-ca-template.yaml docker-compose-ca.yaml
  
  # 当前目录
  CURRENT_DIR=$PWD

  # 找到新生成的ca私钥名
  cd crypto-config/peerOrganizations/org1.example.com/ca/
  PRIV_KEY=$(ls *_sk)

  # 替换 docker-compose-ca.yaml 中的ca私钥名称
  cd "$CURRENT_DIR"
  sed -i "s/CA_ORG1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-ca.yaml
}


## 生成组织节点身份材料
function generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi

  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi

  set -x
  cryptogen generate --config=./crypto-config.yaml
  res=$?
  set +x

  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}



# 生成order初始块配置、通道初始块配置、两个组织的锚节点配置
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"

  set -x
  configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/orderer.genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/businesschannel.tx -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org1MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org2MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org2MSP..."
    exit 1
  fi
  echo
}

## 退出网络, 删除文件
function networkDown() {

  docker-compose -f $COMPOSE_FILE down --volumes --remove-orphans

  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    #Delete any ledger backups
    docker run -v $PWD:/tmp/$PROJECT_NAME  rm -Rf /tmp/$PROJECT_NAME/ledgers-backup
    #Cleanup the chaincode containers
    clearContainers
    # remove orderer block and other channel configuration transactions and certs
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config
  fi
}


## 启动网络函数
function networkUp() {

  # 如果不存在crypto-config，就去生成组织节点身份材料
  if [ ! -d "crypto-config" ]; then
    generateCerts
    replacePrivateKey
    generateChannelArtifacts
  fi

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! 启动网络失败"
    exit 1
  fi

  # 进入cli容器，之后在容器内执行 scripts/script.sh  $CHANNEL_NAME
  docker exec cli scripts/script.sh $CHANNEL_NAME

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! 测试网络失败"
    exit 1
  fi
}



MODE=$1

if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  generateCerts
  replacePrivateKey
  generateChannelArtifacts
elif [ "${MODE}" == "restart" ]; then ## Restart the network
  networkDown
  networkUp
fi