provider = require './provider'

module.exports =
  activate: ->
    console.log 'autocomplete-weexvue activate'
    provider.loadProperties()
    provider.loadPropertiesVue()

  getProvider: -> provider
