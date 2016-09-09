module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service

  SwitchAccessory = require('./switch')(env)

  ##
  # Lightbulb
  ##
  class LightbulbAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

    getDefaultService: ->
      return Service.Lightbulb
