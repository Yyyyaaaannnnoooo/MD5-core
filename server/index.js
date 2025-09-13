const express = require('express');
const { createServer } = require('node:http');
const path = require('path')
const { join } = require('node:path');
const { Server } = require('socket.io');

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: ["http://127.0.0.1:3000","http://127.0.0.1:5500"]
  }
});


app.use(express.static(path.join(__dirname, '..', 'client')));
app.get('/', (req, res) => {
  // res.sendFile(join(__dirname, 'index.html'));
  const filePath = path.join(__dirname, '..', 'client', 'index.html');
  res.sendFile(filePath);
});

io.on('connection', (socket) => {
  console.log('CONNECTION');
  socket.on("msg", msg => {
    console.log(msg);
    make_md5_hash(msg)
  })
  socket.on("panic", msg => {
    console.log(msg);
    send_panic()
  })
});


server.listen(3000, () => {
  console.log('server running at http://localhost:3000');
});

const osc = require("osc")
const local_address = "127.0.0.1"
const local_port = 57121
const remote_port = 57120

// Create an osc.js UDP Port listening on port 57121.
const udpPort = new osc.UDPPort({
  localAddress: "127.0.0.1",
  localPort: local_port,
  metadata: true
});

// Listen for incoming OSC messages.
udpPort.on("message", function (oscMsg, timeTag, info) {
  console.log("An OSC message just arrived!", oscMsg);
  if (oscMsg["address"] === "/play") {
    io.emit("play", oscMsg["args"][0]["value"]);
  }else if(oscMsg["address"] === "/composition"){
    io.emit("composition", oscMsg["args"][0]["value"])
  } 
  else {

    const value = oscMsg["args"][0]["value"];
    const midi_ch = oscMsg["args"][1]["value"];
    make_md5_hash(value);
  }
  // console.log("Remote info is: ", info);
  // console.log(oscMsg["args"][0]["value"]);
  // const byte = stringToByteArray(md5)
  // console.log(byte);
  // console.log(byte.length);
  // send_osc(byte)
});

// Open the socket.
udpPort.open();


// // When the port is read, send an OSC message to, say, SuperCollider
udpPort.on("ready", function () {
  console.log("Connected with SuperCollider");
});


function make_md5_hash(value) {
  const md5 = MD5(value);
  console.log(md5);
  const hex = hexToBytesWithBuffer(md5);
  console.log(hex);
  // hex.unshift(midi_ch);
  console.log(hex.length);
  io.emit("hash", md5);
  send_osc(hex);
}

function hexToBytesWithBuffer(hex) {
  const list = hex.split('');
  const result = []
  list.forEach(element => {
    const val = parseInt(element, 16);
    result.push(val)
  });
  // return Array.from(Buffer.from(hex, 'hex'));
  return result;
}


function send_osc(msg) {
  udpPort.send({
    address: "/md5",
    args: make_message(msg)
  }, local_address, remote_port);
}
function send_panic() {
  udpPort.send({
    address: "/panic",
    args: { type: 's', value: 'PANIC!' }
  }, local_address, remote_port);
}

function emit_md5_parts(md5){
  io.emit("md5-part", md5);
}

function make_message(array) {
  result = []
  for (let i = 0; i < array.length; i++) {
    const val = array[i];
    result.push({
      type: "i",
      value: val
    })
  }
  return result
}

function stringToByteArray(str) {
  const byteArray = [];
  for (let i = 0; i < str.length; i++) {
    byteArray.push(str.charCodeAt(i));
  }
  return byteArray;
}


MD5 = function (e) {
  const md5_parts = [];
  function h(a, b) {
    var c, d, e, f, g;
    e = a & 2147483648;
    f = b & 2147483648;
    c = a & 1073741824;
    d = b & 1073741824;
    g = (a & 1073741823) + (b & 1073741823);
    return c & d ? g ^ 2147483648 ^ e ^ f : c | d ? g & 1073741824 ? g ^ 3221225472 ^ e ^ f : g ^ 1073741824 ^ e ^ f : g ^ e ^ f
  }

  function k(a, b, c, d, e, f, g) {
    a = h(a, h(h(b & c | ~b & d, e), g));
    md5_parts.push(a.toString());
    return h(a << f | a >>> 32 - f, b)
  }

  function l(a, b, c, d, e, f, g) {
    a = h(a, h(h(b & d | c & ~d, e), g));
    md5_parts.push(a.toString());
    return h(a << f | a >>> 32 - f, b)
  }

  function m(a, b, d, c, e, f, g) {
    a = h(a, h(h(b ^ d ^ c, e), g));
    md5_parts.push(a.toString());
    return h(a << f | a >>> 32 - f, b)
  }

  function n(a, b, d, c, e, f, g) {
    a = h(a, h(h(d ^ (b | ~c), e), g));
    md5_parts.push(a.toString());
    return h(a << f | a >>> 32 - f, b)
  }

  function p(a) {
    var b = "",
      d = "",
      c;
    for (c = 0; 3 >= c; c++) d = a >>> 8 * c & 255, d = "0" + d.toString(16), b += d.substr(d.length - 2, 2);
    md5_parts.push(b.toString());
    return b
  }
  var f = [],
    q, r, s, t, a, b, c, d;
  e = function (a) {
    a = a.replace(/\r\n/g, "\n");
    for (var b = "", d = 0; d < a.length; d++) {
      var c = a.charCodeAt(d);
      128 > c ? b += String.fromCharCode(c) : (127 < c && 2048 > c ? b += String.fromCharCode(c >> 6 | 192) : (b += String.fromCharCode(c >> 12 | 224), b += String.fromCharCode(c >> 6 & 63 | 128)), b += String.fromCharCode(c & 63 | 128))
    }
    md5_parts.push(b.toString());
    return b
  }(e);
  f = function (b) {
    var a, c = b.length;
    a = c + 8;
    for (var d = 16 * ((a - a % 64) / 64 + 1), e = Array(d - 1), f = 0, g = 0; g < c;) a = (g - g % 4) / 4, f = g % 4 * 8, e[a] |= b.charCodeAt(g) << f, g++;
    a = (g - g % 4) / 4;
    e[a] |= 128 << g % 4 * 8;
    e[d - 2] = c << 3;
    e[d - 1] = c >>> 29;
    // md5_parts.push(e.toString());
    return e
  }(e);
  a = 1732584193;
  b = 4023233417;
  c = 2562383102;
  d = 271733878;
  for (e = 0; e < f.length; e += 16) q = a, r = b, s = c, t = d, a = k(a, b, c, d, f[e + 0], 7, 3614090360), d = k(d, a, b, c, f[e + 1], 12, 3905402710), c = k(c, d, a, b, f[e + 2], 17, 606105819), b = k(b, c, d, a, f[e + 3], 22, 3250441966), a = k(a, b, c, d, f[e + 4], 7, 4118548399), d = k(d, a, b, c, f[e + 5], 12, 1200080426), c = k(c, d, a, b, f[e + 6], 17, 2821735955), b = k(b, c, d, a, f[e + 7], 22, 4249261313), a = k(a, b, c, d, f[e + 8], 7, 1770035416), d = k(d, a, b, c, f[e + 9], 12, 2336552879), c = k(c, d, a, b, f[e + 10], 17, 4294925233), b = k(b, c, d, a, f[e + 11], 22, 2304563134), a = k(a, b, c, d, f[e + 12], 7, 1804603682), d = k(d, a, b, c, f[e + 13], 12, 4254626195), c = k(c, d, a, b, f[e + 14], 17, 2792965006), b = k(b, c, d, a, f[e + 15], 22, 1236535329), a = l(a, b, c, d, f[e + 1], 5, 4129170786), d = l(d, a, b, c, f[e + 6], 9, 3225465664), c = l(c, d, a, b, f[e + 11], 14, 643717713), b = l(b, c, d, a, f[e + 0], 20, 3921069994), a = l(a, b, c, d, f[e + 5], 5, 3593408605), d = l(d, a, b, c, f[e + 10], 9, 38016083), c = l(c, d, a, b, f[e + 15], 14, 3634488961), b = l(b, c, d, a, f[e + 4], 20, 3889429448), a = l(a, b, c, d, f[e + 9], 5, 568446438), d = l(d, a, b, c, f[e + 14], 9, 3275163606), c = l(c, d, a, b, f[e + 3], 14, 4107603335), b = l(b, c, d, a, f[e + 8], 20, 1163531501), a = l(a, b, c, d, f[e + 13], 5, 2850285829), d = l(d, a, b, c, f[e + 2], 9, 4243563512), c = l(c, d, a, b, f[e + 7], 14, 1735328473), b = l(b, c, d, a, f[e + 12], 20, 2368359562), a = m(a, b, c, d, f[e + 5], 4, 4294588738), d = m(d, a, b, c, f[e + 8], 11, 2272392833), c = m(c, d, a, b, f[e + 11], 16, 1839030562), b = m(b, c, d, a, f[e + 14], 23, 4259657740), a = m(a, b, c, d, f[e + 1], 4, 2763975236), d = m(d, a, b, c, f[e + 4], 11, 1272893353), c = m(c, d, a, b, f[e + 7], 16, 4139469664), b = m(b, c, d, a, f[e + 10], 23, 3200236656), a = m(a, b, c, d, f[e + 13], 4, 681279174), d = m(d, a, b, c, f[e + 0], 11, 3936430074), c = m(c, d, a, b, f[e + 3], 16, 3572445317), b = m(b, c, d, a, f[e + 6], 23, 76029189), a = m(a, b, c, d, f[e + 9], 4, 3654602809), d = m(d, a, b, c, f[e + 12], 11, 3873151461), c = m(c, d, a, b, f[e + 15], 16, 530742520), b = m(b, c, d, a, f[e + 2], 23, 3299628645), a = n(a, b, c, d, f[e + 0], 6, 4096336452), d = n(d, a, b, c, f[e + 7], 10, 1126891415), c = n(c, d, a, b, f[e + 14], 15, 2878612391), b = n(b, c, d, a, f[e + 5], 21, 4237533241), a = n(a, b, c, d, f[e + 12], 6, 1700485571), d = n(d, a, b, c, f[e + 3], 10, 2399980690), c = n(c, d, a, b, f[e + 10], 15, 4293915773), b = n(b, c, d, a, f[e + 1], 21, 2240044497), a = n(a, b, c, d, f[e + 8], 6, 1873313359), d = n(d, a, b, c, f[e + 15], 10, 4264355552), c = n(c, d, a, b, f[e + 6], 15, 2734768916), b = n(b, c, d, a, f[e + 13], 21, 1309151649), a = n(a, b, c, d, f[e + 4], 6, 4149444226), d = n(d, a, b, c, f[e + 11], 10, 3174756917), c = n(c, d, a, b, f[e + 2], 15, 718787259), b = n(b, c, d, a, f[e + 9], 21, 3951481745), a = h(a, q), b = h(b, r), c = h(c, s), d = h(d, t);
  const result = (p(a) + p(b) + p(c) + p(d)).toLowerCase()
  md5_parts.push(result)
  emit_md5_parts(md5_parts)
  return result
};

// SOURCE  : https://stackoverflow.com/questions/1655769/fastest-md5-implementation-in-javascript
// SOURCE 2: https://gist.github.com/souhaiebtar/f0e064152b70902f2cd58cf9b8311be9