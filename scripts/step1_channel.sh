# 设置通用环境变量
echo "*************  设置通用环境变量 ****************"

CHANNEL_NAME=businesschannel
ORDERER_CA=/etc/hyperledger/fabric/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "CHANNEL_NAME=${CHANNEL_NAME}"
echo "ORDERER_CA=${ORDERER_CA}"

# 创建通道
echo "*************  创建通道 ****************"
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051 
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f ./channel-artifacts/businesschannel.tx --tls --cafile ${ORDERER_CA}

echo "*************  成功创建通道 ${CHANNEL_NAME}.block ****************"

sleep 5

# 把peer0.org1 加入通道
echo "*************  把 peer0.org1 加入通道 ****************"
peer channel join  -b ${CHANNEL_NAME}.block 
echo "*************  peer0.org1 成功 加入通道 ****************"
sleep 3

# 把peer1.org1 加入通道
echo "*************  把 peer1.org1 加入通道 ****************"
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer1.org1.example.com:7051 
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt

peer channel join  -b ${CHANNEL_NAME}.block 
echo "*************  peer1.org1 成功 加入通道 ****************"
sleep 3

# 把peer0.org2 加入通道
echo "*************  把 peer0.org2 加入通道 ****************"
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

peer channel join  -b ${CHANNEL_NAME}.block 

echo "*************  peer0.org2 成功 加入通道 ****************"
sleep 3


# 把peer1.org2 加入通道
echo "*************  把peer1.org2加入通道 ****************"
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer1.org2.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt

peer channel join  -b ${CHANNEL_NAME}.block 

echo "*************  peer1.org2 成功 加入通道 ****************"
sleep 3

# 更新org1的锚节点配置
echo "*************  更新 org1 的锚节点配置 ****************"
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051 
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel update  -o orderer.example.com:7050  -c ${CHANNEL_NAME}  -f ./channel-artifacts/Org1MSPanchors.tx   --tls --cafile ${ORDERER_CA}
echo "*************  成功更新 org1 的锚节点配置 ****************"
sleep 3

# 更新org2的锚节点配置
echo "*************  更新 org2 的锚节点配置 ****************"
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:7051 
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

peer channel update  -o orderer.example.com:7050  -c ${CHANNEL_NAME}  -f ./channel-artifacts/Org2MSPanchors.tx   --tls --cafile ${ORDERER_CA}

echo "*************  成功更新 org2 的锚节点配置 ****************"
sleep 3

echo "*************  通道创建和配置结束 ****************"
echo "*************  通道创建和配置结束 ****************"
echo "*************  通道创建和配置结束 ****************"
echo "*************  通道创建和配置结束 ****************"

sleep 3
