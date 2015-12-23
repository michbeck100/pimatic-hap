module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # ShutterController
  #
  # currently shutter is using Service.LockMechanism because Service.Window uses percentages
  # for moving the shutter which is not supported by ShutterController devices
  class ShutterAccessory extends BaseAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.LockMechanism, device.name)
        .getCharacteristic(Characteristic.LockTargetState)
        .on 'set', (value, callback) =>
          promise = null
          if value == Characteristic.LockTargetState.UNSECURED
            promise = device.moveUp()
          else if value == Characteristic.LockTargetState.SECURED
            promise = device.moveDown()
          if (promise != null)
            @handleVoidPromise(promise, callback)

      @getService(Service.LockMechanism)
        .getCharacteristic(Characteristic.LockTargetState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPosition(), callback, @getLockCurrentState)

      # opposite of target position getter
      @getService(Service.LockMechanism)
        .getCharacteristic(Characteristic.LockCurrentState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPosition(), callback, @getLockCurrentState)

      device.on 'position', (position) =>
        @getService(Service.LockMechanism)
          .setCharacteristic(Characteristic.LockCurrentState, @getLockCurrentState(position))

    getLockCurrentState: (position) =>
            if position == 'up'
              return Characteristic.LockCurrentState.UNSECURED
            else if position == "down"
              return Characteristic.LockCurrentState.SECURED
            else
              # stopped somewhere in between
              return Characteristic.LockCurrentState.UNKNOWN
