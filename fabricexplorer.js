var co = require('co');
var fabricservice = require('./fabricservice.js')
var express = require('express');
var app = express();

// 获取当前通道的高度
app.get('/getchannelheight', function (req, res) {
  co(function* () {
    var blockchaininfo = yield fabricservice.getBlockChainInfo();
    res.send(blockchaininfo.height.toString());
  }).catch((err) => {
    res.send(err);
  })
});

// 根据区块的编号获取区块的信息
app.get('/getblockInfobyNum', function (req, res) {
  let num  = req.query.num;

  if(!num){
    return res.send('缺少编号')
  }

  co(function* () {
    var blockinfo = yield fabricservice.getblockInfobyNum(num);
    res.send(JSON.stringify(blockinfo));
  }).catch((err) => {
    res.send(err);
  })
});

// 根据区块的Hash值来获取区块的信息
app.get('/getblockInfobyHash', function (req, res) {
  let hash  = req.query.hash || '';

  if(!hash){
    return res.send('缺少hash')
  }

  co(function* () {
    var blockinfo = yield fabricservice.getblockInfobyHash(hash);
    res.send(JSON.stringify(blockinfo));
  }).catch((err) => {
    res.send(err);
  })
});


// 获取制定Peer节点加入的通道数
app.get('/getPeerChannel', function (req, res) {
  co(function* () {
    var peerJoinchannels = yield fabricservice.getPeerChannel();
    res.send(JSON.stringify(peerJoinchannels));
  })
});

app.get('/sendTransaction', function (req, res) {
  co(function* () {
    var blockinfo = yield fabricservice.sendTransaction("cc_endfinlshed", "invoke", ["a", "b", "1"], "roberttestchannel12");
    res.send("success");
  })
});
// 启动http服务
var server = app.listen(3000, function () {
  var host = server.address().address;
  var port = server.address().port;
  console.log('Example app listening at http://%s:%s', host, port);
});


// 注册异常处理器
process.on('unhandledRejection', function (err) {
  console.error(err.stack);
});
process.on(`uncaughtException`, console.error);