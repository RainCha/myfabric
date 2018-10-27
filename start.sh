echo "生成组织身份资料"
cryptogen generate --config=./crypto-config.yaml --output crypto-config


echo "生成orderer创始块"
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./orderer.genesis.block

echo "生成channel创始块配置文件"
CHANNEL_NAME=businesschannel
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./businesschannel.tx -channelID ${CHANNEL_NAME}

## 生成锚节点
echo "为组织1生成锚节点配置文件"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID ${CHANNEL_NAME}  -asOrg Org1MSP

echo "为组织2生成锚节点配置文件"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org2MSPanchors.tx -channelID ${CHANNEL_NAME}  -asOrg Org2MSP