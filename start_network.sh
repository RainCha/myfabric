# 以防万一，删除之前的遗留文件
docker rm $(docker ps -q -f status=exited)

rm -rf channel-artifacts
rm -rf crypto-config


sleep 3

# 创建存储配置文件的文件夹
mkdir ./channel-artifacts

echo "生成组织身份资料"
cryptogen generate --config=./crypto-config.yaml --output crypto-config


echo "生成orderer创始块"
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/orderer.genesis.block

echo "生成channel创始块配置文件"
CHANNEL_NAME=businesschannel
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/businesschannel.tx -channelID ${CHANNEL_NAME}

## 生成锚节点
echo "为组织1生成锚节点配置文件"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID ${CHANNEL_NAME}  -asOrg Org1MSP

echo "为组织2生成锚节点配置文件"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID ${CHANNEL_NAME}  -asOrg Org2MSP


echo "启动网络容器"
docker-compose -f ./docker-compose-cli.yaml up
