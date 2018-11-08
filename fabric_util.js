var path = require('path');
var fs = require('fs');
var hfc = require('fabric-client');

// 临时存放目录
var tempdir = "./newUsers";

// client实例
let client = new hfc();

const CHANNEL_NAME = 'businesschannel'

var channel = client.newChannel(CHANNEL_NAME);

var order = client.newOrderer('grpc://localhost:7050');
channel.addOrderer(order);
var peer0_Ogr1 = client.newPeer('grpc://localhost:7051');
channel.addPeer(peer0_Ogr1);
var peer1_Ogr1 = client.newPeer('grpc://localhost:8051');
channel.addPeer(peer1_Ogr1);

/**
 * 使用本地已有用户的信息，去注册新用户
 */
async function getOrgUserLocal() {
  var keyPath = "./crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore";
  var keyPEM = Buffer
    .from(readAllFiles(keyPath)[0])
    .toString();
  var certPath = "./crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts";
  var certPEM = readAllFiles(certPath)[0].toString();

  let store = await hfc.newDefaultKeyValueStore({
    path: tempdir
  })

  client.setStateStore(store);

  let user = await client.createUser({
    username: 'user10',
    mspid: 'Org1MSP',
    cryptoContent: {
      privateKeyPEM: keyPEM,
      signedCertPEM: certPEM
    }
  });

  return user;
};


function readAllFiles(dir) {
  var files = fs.readdirSync(dir);
  var certs = [];
  files.forEach((file_name) => {
    let file_path = path.join(dir, file_name);
    let data = fs.readFileSync(file_path);
    certs.push(data);
  });
  return certs;
}


// 查询区块链信息

/** 
 * 获取channel的区块链信息 
 * @returns {Promise.<TResult>} 
 * */
var getBlockChainInfo = async function () {
  let user = await getOrgUserLocal();
  let info = await channel.queryInfo(peer0_Ogr1);
  console.log(info, 111)
}

getBlockChainInfo();