assert = require "assert"
grunt = require "grunt"

describe "base", ->

  uuid = require ('hap-nodejs/lib/util/uuid')

  BaseAccessory = require("../accessories/base")(null)

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
