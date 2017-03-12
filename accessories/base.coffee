module.exports = (env) ->

  hap = require 'hap-nodejs'
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')

  # base class for all homekit accessories in pimatic
  class BaseAccessory extends Accessory

    hapConfig: null

    constructor: (device, deviceId, deviceName) ->
      # this handling is needed in order to support pimatic devices
      # which need to be represented by mutiple homekit devices
      # as function overloading is not supportet in node

      if !deviceId?
        # deviceId was omitted in constructor call thus we need to fill it accordingly
        deviceId = device.id
        # same for deviceName
        deviceName = device.name
        # to stay compatible we will only use the deviceId for serial generation
        deviceSerialId = deviceId
      else
        # if the parameters were passed to the constructor (and likely to be modified)
        # we will use a combination of deviceId and deviceName for generating the serial
        deviceSerialId = deviceId + deviceName

      @hapConfig = device.config.hap

      serialNumber = uuid.generate('pimatic-hap:accessories:' + deviceSerialId)
      super(deviceName, serialNumber)

      @getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, serialNumber)

      @addService(Service.BridgingState)
        .getCharacteristic(Characteristic.Reachable)
        .on 'set', (value, callback) =>
          env.logger.warn 'accessory ' + deviceId + ' was set to unreachable!' unless value
          callback()

      @on 'identify', (paired, callback) =>
        @identify(device, paired, callback)

    ## default identify method just calls callback
    identify: (device, paired, callback) =>
      callback()

    ## calls promise, then callback, and handles errors
    handleVoidPromise: (promise, callback) =>
      promise
        .then( => callback() )
        .catch( (error) =>
          env.logger.error "Could not call promise: " + error.message
          env.logger.debug error.stack
          callback(error)
        )
        .done()

    handleReturnPromise: (promise, callback, converter) =>
      promise
        .then( (value) =>
          if converter != null
            value = converter(value)
          callback(null, value)
        )
        .catch( (error) =>
          env.logger.error "Could not call promise: " + error.message
          env.logger.debug error.stack
          callback(error, null)
        )
        .done()

    exclude: =>
      if @hapConfig != null && @hapConfig != undefined
        return @hapConfig.exclude != null && @hapConfig.exclude
      return false
