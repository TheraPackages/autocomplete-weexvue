provider = require './provider'

module.exports =
  activate: ->
    provider.loadProperties()
    provider.loadPropertiesVue()

  getProvider: -> provider
