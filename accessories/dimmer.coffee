module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  SwitchAccessory = require('./switch')(env)

  ##
  # DimmerActuator
  ##
  class DimmerAccessory extends SwitchAccessory

    _dimlevel: null

    constructor: (device) ->
      super(device)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getDimlevel(), callback, null)

      device.on 'dimlevel', (dimlevel) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Brightness, dimlevel)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          @_dimlevel = device._dimlevel
          if @_dimlevel != null
            if @_dimlevel is value 
              env.logger.debug 'value ' + value +
                ' equals current dimlevel of ' + device.name  + '. Not changing.'
              callback()
              return
            env.logger.debug 'changing dimlevel of ' + device.name + ' to ' + value
            @_dimlevel = value
            @_state = value > 0
            @handleVoidPromise(device.changeDimlevelTo(value), callback)
          else
            #if we don't have a dim level yet we can not properly determine whether to dim or not
            env.logger.debug "Device #{device.name} dim level not initialized yet, 
            ignoring dim level change"
            callback()
            return

    getDefaultService: =>
      return Service.Lightbulb
