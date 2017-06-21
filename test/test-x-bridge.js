var bridge = require('../build/Release/x-bridge.node');
console.log(`cpu_addr_size = ${bridge.cpu_addr_size()}`);
var s = bridge.parse('dwdwdw', 12, 12);
console.log(s);
