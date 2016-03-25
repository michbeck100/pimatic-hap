module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service

  SwitchAccessory = require('./switch')(env)

  ##
  # PowerSwitch
  ##
  class PowerSwitchAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

    getDefaultService: =>
      return Service.Switch
