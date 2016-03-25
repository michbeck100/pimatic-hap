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

  turnOn: ->
    @_state = on
    return Promise.resolve()

  turnOff: ->
    @_state = off
    return Promise.resolve()

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
