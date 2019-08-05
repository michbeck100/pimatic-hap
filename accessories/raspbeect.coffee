module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DimmerAccessory = require('./dimmer')(env)

  class RaspBeeCTAccessory extends DimmerAccessory

    _ct = null
    #ctmin = 140
    #ctmax = 500

    constructor: (device) ->
      super(device)
      _ct = device._ct

      @service.getCharacteristic(Characteristic.ColorTemperature)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getCt(), callback, @getColorTemp)

      @service.getCharacteristic(Characteristic.ColorTemperature)
        .on 'set', (value, callback) =>
          ncol=Math.round((Math.min(Math.max(((value-140)/(500-140)), 0), 1))*100)
          if ncol is @_ct
            callback()
            return
          @_ct = ncol
          @handleVoidPromise(device.setCT(ncol), callback)

      device.on 'ct', (ct) =>
        @service.updateCharacteristic(Characteristic.ColorTemperature, @getColorTemp(ct))


    getColorTemp: (color) =>
      return Math.round(140 + color / 100 * (500-140))
