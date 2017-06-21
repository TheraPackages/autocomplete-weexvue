(function () {

  function x(text, row, column) {

    // cross platform library
    function getSharedLib(bridge) {
      if ('darwin' == process.platform) {
        return '/../shared/darwin/libx.dylib';
      } else if ('win32' == process.platform) {
        if (bridge.cpu_addr_size() == 64) {
          return '\\..\\shared\\win32\\libx.dll';
        } else if (bridge.cpu_addr_size() == 32) {
          return '\\..\\shared\\win32\\x86\\libx.dll';
        }
      }
    }

    var bridge = require('../build/Release/x-bridge.node');
    var libname = getSharedLib(bridge);

    if (libname && bridge.load(__dirname + libname, 'autocomplete')) {
        var x = bridge.parse(text, row, column);
        bridge.clear();
        return x;
    }
  }

  module.exports = x;
})();
