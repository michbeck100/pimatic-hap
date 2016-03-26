grunt = require 'grunt'
assert = require "assert"
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
SwitchAccessory = require("../accessories/switch")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestSwitch extends require('events').EventEmitter
  id: "testswitch-id"
  name: "testswitch"
  config: {}
  _state: null

  getState: -> Promise.resolve(@_state)

  turnOn: ->
    @_state = on
    return Promise.resolve()

  turnOff: ->
    @_state = off
    return Promise.resolve()

  fireChange: ->
    @emit 'state', on

class TestAccessory extends SwitchAccessory

  getDefaultService: ->
    return Service.Switch

  toggle: (state) ->
    @getService(Service.Switch)
      .setCharacteristic(Characteristic.On, state)

describe "switch", ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestSwitch()
    accessory = new TestAccessory(device)

  describe "changing Characteristic.On", ->

    it "should turn device on if set to true", ->
      accessory.toggle(true)

      assert device._state is on

    it "should turn device off if set to false", ->
      accessory.toggle(false)

      assert device._state is off

    it "should not turn device on again after being turned on", ->
      accessory.toggle(true)
      device._state = null
      accessory.toggle(true)
      assert device._state is null

    it "should return state when get event is fired", ->
      assertState = (state) ->
        accessory.toggle(state)
        accessory.getService(Service.Switch)
          .getCharacteristic(Characteristic.On)
          .getValue((error, value) ->
            assert error is null
            assert value is state
          )

      assertState(true)
      assertState(false)

    it "should handle state event and set Characteristic.On", ->
      device.fireChange()
      assert device._state is on
      device._state = null
      device.fireChange()
      assert device._state is null
