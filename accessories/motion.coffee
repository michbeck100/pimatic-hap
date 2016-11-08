module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DefaultAccessory = require('./default')(env)

  ##
  # PresenceSensor
  ##
  class MotionAccessory extends DefaultAccessory

    constructor: (device) ->
      super(device, Service.MotionSensor)

      @service.getCharacteristic(Characteristic.MotionDetected)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPresence(), callback, null)

      device.on 'presence', (motionDetected) =>
        @service.setCharacteristic(Characteristic.MotionDetected, motionDetected)
