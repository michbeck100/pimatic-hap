grunt = require "grunt"
assert = require "assert"
env = require('pimatic/startup').env

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

  describe "add service", ->

    it "should register the powerswitch service ", ->

      device = new TestSwitch()
      powerswitch = new PowerSwitchAccessory(device)
      service = powerswitch.getService(Service.Switch)
      assert service?
