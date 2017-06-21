(function () {

  function x(text, row, column) {

    // cross platform library
    function getSharedLib() {
      if ('darwin' == process.platform) {
        return '/../shared/darwin/libx.dylib';
      } else if ('win32' == process.platform) {
        return '\\..\\shared\\win32\\libx.dll';
      }
    }

    var bridge = require('../build/Release/x-bridge.node');
    var libname = getSharedLib();

    if (libname && bridge.load(__dirname + libname, 'autocomplete')) {
        var x = bridge.parse(text, row, column);
        bridge.clear();
        return x;
    }
  }

  module.exports = x;
})();
