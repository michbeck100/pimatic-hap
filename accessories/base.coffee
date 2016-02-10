module.exports = (env) ->

  hap = require 'hap-nodejs'
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')

  # base class for all homekit accessories in pimatic
  class BaseAccessory extends Accessory

    constructor: (device) ->
      serialNumber = uuid.generate('pimatic-hap:accessories:' + device.id)
      super(device.name, serialNumber)
      # accessories are reachable as long as the server lives
      this.reachable = true

      @getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, serialNumber);

      @addService(Service.BridgingState)
        .getCharacteristic(Characteristic.Reachable)
        .on 'set', (value, callback) =>
          env.logger.warn 'accessory ' + device.id + ' was set to unreachable!' unless value
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
