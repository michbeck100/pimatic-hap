grunt = require 'grunt'
assert = require 'assert'
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
    error: (stmt) ->
      grunt.log.writeln stmt
ShutterAccessory = require("../accessories/shutter")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestShutter extends require('events').EventEmitter
  id: "testshutter-id"
  name: "testshutter"
  config: {}

  _position: null

  getPosition: ->
    Promise.resolve(@_position)

  firePositionChange: (position) ->
    @_position = position
    @emit 'position', position

  moveUp: ->
    @_position = "up"
    @firePositionChange(@_position)
    return Promise.resolve()

  moveDown: ->
    @_position = "down"
    @firePositionChange(@_position)
    return Promise.resolve()

  stop: ->
    @_position = "stopped"
    @firePositionChange(@_position)
    return Promise.resolve()

describe "shutter", ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestShutter()
    accessory = new ShutterAccessory(device)

  describe "getting Characteristic.CurrentDoorState", ->

    it "should return CLOSED when position is down", ->
      device._position = 'down'
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.CurrentDoorState)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.CurrentDoorState.CLOSED
        )
    it "should return OPEN when position is up", ->
      device._position = 'up'
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.CurrentDoorState)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.CurrentDoorState.OPEN
        )

    it "should return STOPPED when position is stopped", ->
      device._position = 'stopped'
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.CurrentDoorState)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.CurrentDoorState.STOPPED
        )

  describe "changing position", ->

    it "should change Characteristic.CurrentDoorState", ->
      device.firePositionChange('down')
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.CurrentDoorState)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.CurrentDoorState.CLOSED
        )

  describe "changing Characteristic.TargetDoorState", ->

    it "should call moveUp() when set to OPEN", ->
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.TargetDoorState)
        .setValue(Characteristic.TargetDoorState.OPEN)
      assert device._position is 'up'

    it "should call moveDown() when set to CLOSED", ->
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.TargetDoorState)
        .setValue(Characteristic.TargetDoorState.CLOSED)
      assert device._position is 'down'

    it "should call stop() when set to OPEN twice", ->
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.TargetDoorState)
        .setValue(Characteristic.TargetDoorState.OPEN)
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.TargetDoorState)
        .setValue(Characteristic.TargetDoorState.OPEN)
      assert device._position is 'stopped'

    it "should set Characteristic.CurrentDoorState", ->
      getCurrentState = () =>
        return accessory.getService(Service.GarageDoorOpener)
          .getCharacteristic(Characteristic.CurrentDoorState)
          .value
      env.logger.debug 'getCurrentState = ' + getCurrentState()
      assert getCurrentState() != Characteristic.CurrentDoorState.CLOSED
      accessory.getService(Service.GarageDoorOpener)
        .getCharacteristic(Characteristic.TargetDoorState)
        .setValue(Characteristic.TargetDoorState.CLOSED)
      assert getCurrentState() == Characteristic.CurrentDoorState.CLOSED

  describe "getCurrentState", ->

    it "should return correct value", ->
      assert accessory.getCurrentState('up') is Characteristic.CurrentDoorState.OPEN
      assert accessory.getCurrentState('down') is Characteristic.CurrentDoorState.CLOSED
      assert accessory.getCurrentState('stopped') is Characteristic.CurrentDoorState.STOPPED

    it "should trow an error when used with wrong value", ->
      fn = () -> accessory.getCurrentState('bla')
      require('chai').expect(fn).to.throw(assert.AssertionError)

  describe "getTargetPosition", ->

    it "should return correct value", ->
      assert accessory.getTargetPosition(Characteristic.TargetDoorState.OPEN) is 'up'
      assert accessory.getTargetPosition(Characteristic.TargetDoorState.CLOSED) is 'down'
