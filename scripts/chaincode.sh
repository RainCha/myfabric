
# 为 peer0.org1 安装链码
# 设置通用环境变量
echo "*************  设置通用环境变量  ****************"

CHANNEL_NAME=businesschannel
ORDERER_CA=/etc/hyperledger/fabric/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "CHANNEL_NAME=${CHANNEL_NAME}"
echo "ORDERER_CA=${ORDERER_CA}"

# 配置 环境变量
echo "*************  配置链码环境变量  ****************"
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051 
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt


# 安装链码
echo "*************  安装链码  ****************"
peer chaincode install  -n test_cc  -v 1.0  -p github.com/hyperledger/fabric/myfabric/chaincode/go

# 实例化链码
echo "*************  实例化链码  ****************"
peer chaincode instantiate  -o orderer.example.com:7050   -C ${CHANNEL_NAME}   -n test_cc  -v 1.0  -c '{"Args":["init","a","100","b","200"]}'   -P "OR ('Org1MSP.member','Org2MSP.member')"    --tls   --cafile ${ORDERER_CA}

# 实例化过程较慢，所以休眠进程5秒
sleep 5

# 调用链码
echo "*************  调用链码  ****************"
peer chaincode query   -n test_cc   -C ${CHANNEL_NAME}  -c '{"Args":["query","a"]}'

# 转账操作
echo "*************  转账操作  ****************"
peer chaincode invoke   -o orderer.example.com:7050     -C ${CHANNEL_NAME}    -n test_cc     -c '{"Args":["invoke","a","b","10"]}'    --tls   --cafile ${ORDERER_CA}


# 实例化过程较慢，所以休眠进程3秒
sleep 3

# 再次查询
echo "*************  再次查询  ****************"
peer chaincode query   -n test_cc   -C ${CHANNEL_NAME}  -c '{"Args":["query","a"]}'
