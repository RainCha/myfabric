var path = require('path');
var fs = require('fs');

var hfc = require('fabric-client');
var Peer = require('fabric-client/lib/Peer.js');
var EventHub = require('fabric-client/lib/EventHub.js');
var User = require('fabric-client/lib/User.js');

var log4js = require('log4js');
var logger = log4js.getLogger('Helper');
logger.setLevel('DEBUG');


var tempdir = "/project/ws_nodejs/fabric_sdk_node_studynew/fabric-client-kvs";

// 
let client = new hfc();
var channel = client.newChannel('roberttestchannel12');

var order = client.newOrderer('grpc://192.168.23.212:7050');
channel.addOrderer(order);
var peer188 = client.newPeer('grpc://172.16.10.188:7051');
channel.addPeer(peer188);
var peer = client.newPeer('grpc://192.168.23.212:7051');
channel.addPeer(peer);

/** 
 * 获取channel的区块链信息 
 * @returns {Promise.<TResult>} 
 * */
var getBlockChainInfo = function () {
  return getOrgUser4Local().then((user) => {
    return channel.queryInfo(peer);
  }, (err) => {
    console.log('error', e);
  })
}

/**  
 * 根据区块链的编号获取区块的详细信息
 * @param blocknum 
 * @returns {Promise.<TResult>} 
 * */
var getblockInfobyNum = function (blocknum) {
  return getOrgUser4Local().then((user) => {
    return channel.queryBlock(blocknum, peer, null);
  }, (err) => {
    console.log('error', e);
  })
}

/** 
 * 根据区块链的哈希值获取区块的详细信息 
 * @param blocknum 
 * @returns {Promise.<TResult>} 
 * */
var getblockInfobyHash = function (blockHash) {
  return getOrgUser4Local().then((user) => {
    return channel.queryBlockByHash(new Buffer(blockHash, "hex"), peer)
  }, (err) => {
    console.log('error', e);
  })
}

/** 
 * 获取当前Peer节点加入的通道信息 
 * @param blocknum 
 *  @returns {Promise.<TResult>} 
 * */
var getPeerChannel = function () {
  return getOrgUser4Local().then((user) => {
    return client.queryChannels(peer)
  }, (err) => {
    console.log('error', e);
  })
}
/** 
 * 查询指定peer节点已经install的chaincode 
 * @param blocknum 
 * @returns {Promise.<TResult>}
 * */
var getPeerInstallCc = function () {
  return getOrgUser4Local().then((user) => {
    return client.queryInstalledChaincodes(peer)
  }, (err) => {
    console.log('error', e);
  })
}
/**  
 * 查询指定channel中已经实例化的Chaincode
 * @param blocknum 
 * @returns {Promise.<TResult>}
 */
var getPeerInstantiatedCc = function () {
  return getOrgUser4Local().then((user) => {
    return channel.queryInstantiatedChaincodes(peer)
  }, (err) => {
    console.log('error', e);
  })
}


/**
 * 根据cryptogen模块生成的账号通过Fabric接口进行相关的操作 
 * @returns {Promise.<TResult>}
 */
function getOrgUser4Local() {
  // 测试通过CA命令行生成的证书依旧可以成功的发起交易
  var keyPath = "/project/fabric_resart/config_demo/org1/186/fabric-user/msp/keystore";
  var keyPEM = Buffer
    .from(readAllFiles(keyPath)[0])
    .toString();
  var certPath = "/project/fabric_resart/config_demo/org1/186/fabric-user/msp//signcerts";
  var certPEM = readAllFiles(certPath)[0].toString();

  return hfc
    .newDefaultKeyValueStore({
      path: tempdir
    })
    .then((store) => {
      client.setStateStore(store);
      return client.createUser({
        username: 'user87',
        mspid: 'Org1MSP',
        cryptoContent: {
          privateKeyPEM: keyPEM,
          signedCertPEM: certPEM
        }
      });
    });
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



exports.getBlockChainInfo = getBlockChainInfo;
exports.getblockInfobyNum = getblockInfobyNum;
exports.getblockInfobyHash = getblockInfobyHash;
exports.getPeerChannel = getPeerChannel;
exports.getPeerInstallCc = getPeerInstallCc;
exports.getPeerInstantiatedCc = getPeerInstantiatedCc;
exports.sendTransaction = sendTransaction;