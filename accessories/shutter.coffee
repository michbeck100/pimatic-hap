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
      super(device, Service.GarageDoorOpener)

      @service
        .getCharacteristic(Characteristic.CurrentDoorState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPosition(), callback, @getCurrentState)

      device.on 'position', (position) =>
        if position != 'stopped'
          @_targetState = @getTargetState(position)
          @service.setCharacteristic(Characteristic.TargetDoorState, @_targetState)
        @service.setCharacteristic(Characteristic.CurrentDoorState, @getCurrentState(position))

      @service.getCharacteristic(Characteristic.TargetDoorState)
        .on 'get', ((callback) =>
          callback(null, @_targetState))
        .on 'set', (value, callback) =>
          if value is @_targetState
            env.logger.debug 'value ' + value + ' equals current position of ' +
              device.name + '. Not changing.'
            callback()
            return
          promise = null
          if value == Characteristic.TargetDoorState.OPEN
            promise = device.moveUp()
          else if value == Characteristic.TargetDoorState.CLOSED
            promise = device.moveDown()
          @_targetState = value
          if promise
            @handleVoidPromise(promise, callback)
          else
            callback()

    getCurrentState: (position) ->
      assert position in ['up', 'down', 'stopped']
      return switch position
        when 'up' then Characteristic.CurrentDoorState.OPEN
        when 'down' then Characteristic.CurrentDoorState.CLOSED
        when 'stopped' then Characteristic.CurrentDoorState.STOPPED

    getTargetState: (position) ->
      assert position in ['up', 'down']
      return switch position
        when 'up' then Characteristic.TargetDoorState.OPEN
        when 'down' then Characteristic.TargetDoorState.CLOSED

    getTargetPosition: (state) ->
      return switch state
        when Characteristic.TargetDoorState.OPEN then 'up'
        when Characteristic.TargetDoorState.CLOSED then 'down'
