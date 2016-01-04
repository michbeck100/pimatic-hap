module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # PresenceSensor
  ##
  class MotionAccessory extends BaseAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.MotionSensor, device.name)
        .getCharacteristic(Characteristic.MotionDetected)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPresence(), callback, null)

      device.on 'presence', (motionDetected) =>
        @getService(Service.MotionSensor)
          .setCharacteristic(Characteristic.MotionDetected, motionDetected)
