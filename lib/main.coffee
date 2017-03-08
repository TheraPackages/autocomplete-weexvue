provider = require './provider'

module.exports =
  activate: ->
    console.log 'autocomplete-weex activate'
    provider.loadProperties()

  getProvider: -> provider
