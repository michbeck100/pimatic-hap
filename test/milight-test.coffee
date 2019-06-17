assert = require "assert"
grunt = require "grunt"

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
  require: (module) ->
    require(module)

MilightAccessory = require("../accessories/milight")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestMilight extends require('events').EventEmitter
  id: "testswitch-id"
  name: "testswitch"
  config: {}

describe "milight", ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestMilight()
    accessory = new MilightAccessory(device)

  describe "_getHueInDegree", ->

    it "should return 0 for value 176", ->
      actual = accessory._getHueInDegree(176)
      assert actual is 0, "expected 0, actual is #{actual}"

  describe "_getHueForMilight", ->

    it "should return 176 for 0 degrees", ->
      assert accessory._getHueForMilight(0) is 176
