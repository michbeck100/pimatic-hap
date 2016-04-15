assert = require 'assert'

module.exports = (env) ->
  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # ShutterController
  #
  # currently shutter is using Service.GarageDoorOpener because Service.Window uses percentages
  # for moving the shutter which is not supported by ShutterController devices
  class ShutterAccessory extends BaseAccessory
    _targetState: null

    constructor: (device) ->
      super(device)

      @addService(Service.GarageDoorOpener, device.name)
        .getCharacteristic(Characteristic.CurrentDoorState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPosition(), callback, @getCurrentState)

      device.on 'position', (position) =>
        @getService(Service.GarageDoorOpener)
          .setCharacteristic(Characteristic.CurrentDoorState, @getCurrentState(position))

      @getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.TargetDoorState)
        .on 'get', (callback) =>
          callback(null, @_targetState)

      @getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.TargetDoorState)
        .on 'set', (value, callback) =>
          promise = null
          if value == Characteristic.TargetDoorState.OPEN
            promise = device.moveUp()
          else if value == Characteristic.TargetDoorState.CLOSED
            promise = device.moveDown()
          if @_targetState is value
            promise = device.stop()
          @_targetState = value
          if (promise != null)
            @handleVoidPromise(promise, callback)
          else
            callback()

    getCurrentState: (position) ->
      assert position in ['up', 'down', 'stopped']
      return switch position
        when 'up' then Characteristic.CurrentDoorState.OPEN
        when 'down' then Characteristic.CurrentDoorState.CLOSED
        when 'stopped' then Characteristic.CurrentDoorState.STOPPED

    getTargetPosition: (state) ->
      return switch state
        when Characteristic.TargetDoorState.OPEN then 'up'
        when Characteristic.TargetDoorState.CLOSED then 'down'
