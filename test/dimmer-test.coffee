grunt = require 'grunt'
assert = require "assert"
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
DimmerAccessory = require("../accessories/dimmer")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestDimmer extends require('events').EventEmitter
  id: "id"
  name: "test"
  config: {}
  _dimlevel: null

  changeDimlevelTo: (dimlevel) ->
    @_dimlevel = dimlevel
    return Promise.resolve()

class TestAccessory extends DimmerAccessory

  getDefaultService: ->
    return Service.Lightbulb

  changeBrightness: (value) ->
    @getService(Service.Lightbulb)
      .setCharacteristic(Characteristic.Brightness, value)

describe "dimmer", ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestDimmer()
    accessory = new TestAccessory(device)

  describe "changing Characteristic.Brightness", ->

    it "should set dimlevel", ->
      accessory.changeBrightness(20)

      assert device._dimlevel is 20

    it "should not change dimlevel again after setting to same value", ->
      accessory.changeBrightness(5)
      device._dimlevel = null
      accessory.changeBrightness(5)
      assert device._dimlevel is null

    it "should set the state of switch to on when dimlevel > 0", ->
      accessory._state = off
      accessory.changeBrightness(10)
      assert accessory._state is on

    it "should set the state of switch to off when dimlevel = 0", ->
      accessory._state = on
      accessory.changeBrightness(0)
      assert accessory._state is off
