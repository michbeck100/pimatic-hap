grunt = require "grunt"
assert = require "assert"

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt

describe "powerswitch", ->

  PowerSwitchAccessory = require("../accessories/powerswitch")(env)
  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  class TestSwitch extends require('events').EventEmitter
    id: "testswitch-id"
    name: "testswitch"
    config: {}

  powerswitch = null
  device = null

  describe "init", ->

    it "should register Service.Switch by default", ->
      device = new TestSwitch()
      powerswitch = new PowerSwitchAccessory(device)
      actual = powerswitch.getService(Service.Switch)
      assert actual

    it "should override Service from config", ->
      device = new TestSwitch()
      device.config =
        hap:
          service: "Lightbulb"
      powerswitch = new PowerSwitchAccessory(device)
      actual = powerswitch.getService(Service.Lightbulb)
      assert actual

    it "should ignore unsupported Service from config", ->
      device = new TestSwitch()
      device.config =
        hap:
          service: "foo"
      powerswitch = new PowerSwitchAccessory(device)
      actual = powerswitch.getService(Service.Switch)
      assert actual
