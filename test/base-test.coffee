assert = require "assert"
grunt = require "grunt"

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
  require: (module) ->
    require(module)

describe "base", ->

  uuid = require ('hap-nodejs/dist/lib/util/uuid')
  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require("../accessories/base")(env)

  class TestDevice
    id: "test-id"
    name: "testdevice"
    config: {}

  device = null
  accessory = null

  describe "basics", ->

    it "should set displayName and uuid with only device as parameter", ->
      device = new TestDevice()
      accessory = new BaseAccessory(device)
      assert accessory.displayName is device.name
      assert uuid.isValid(accessory.UUID)

    device = null
    accessory = null

    it "should set displayName and uuid with custom deviceId and deviceName", ->
      device = new TestDevice()
      deviceId = "fancy_device"
      deviceName = "Fancy Device"
      accessory = new BaseAccessory(device, deviceId, deviceName)
      assert accessory.displayName is deviceName
      assert uuid.isValid(accessory.UUID)

    it "should set bridging state", ->
      device = new TestDevice()
      accessory = new BaseAccessory(device)
      service = accessory.getService(Service.BridgingState)
      assert service
      isReachable = false
      service.getCharacteristic(Characteristic.Reachable).getValue((error, value) ->
        isReachable = value
      )
      assert(isReachable)
      linkQuality = 0
      service.getCharacteristic(Characteristic.LinkQuality).getValue((error, value) ->
        linkQuality = value
      )
      assert(linkQuality == 4)
      identifier = null
      service.getCharacteristic(Characteristic.AccessoryIdentifier).getValue((error, value) ->
        identifier = value
      )
      assert(identifier == accessory.UUID)
      category = null
      service.getCharacteristic(Characteristic.Category).getValue((error, value) ->
        category = value
      )
      assert(category == accessory.category)
