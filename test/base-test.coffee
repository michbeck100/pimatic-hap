assert = require "assert"
grunt = require "grunt"

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt

describe "base", ->

  uuid = require ('hap-nodejs/lib/util/uuid')
  hap = require 'hap-nodejs'
  Service = hap.Service

  BaseAccessory = require("../accessories/base")(env)

  class TestDevice
    id: "test-id"
    name: "testdevice"
    config: {}

  device = null
  accessory = null

  describe "basics", ->

    it "should set displayName and uuid", ->
      device = new TestDevice()
      accessory = new BaseAccessory(device)
      assert accessory.displayName is device.name
      assert uuid.isValid(accessory.UUID)
