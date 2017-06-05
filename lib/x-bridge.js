(function () {

  function x(text, row, column) {
    var bridge = require('../build/Release/x-bridge.node');
    if (bridge.load(__dirname + '/../shared/libx.dylib', 'autocomplete')) {
        var x = bridge.parse(text, row, column);
        // console.log(x);
        bridge.clear();
        return x;
    }
  }

  module.exports = x;
})();
