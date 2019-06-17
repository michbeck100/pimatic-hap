grunt = require 'grunt'
assert = require 'assert'
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
  require: (module) ->
    require(module)

TemperatureAccessory = require("../accessories/genericsensor")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestSensor extends require('events').EventEmitter
  id: "testsensor-id"
  name: "testsensor"
  config: {}
  _lowBattery: null

  getTemperature: () =>
    return Promise.resolve(50)

  getHumidity: () =>
    return Promise.resolve(20)

  getLowBattery: () =>
    return Promise.resolve(@_lowBattery)

  fire: () =>
    @emit 'temperature', 30
    @emit 'humidity', 40
    @emit 'lowBattery', true

  hasAttribute: (name) =>
    return true

class TestAccessory extends TemperatureAccessory

  getTemperature: () =>
    @getService(Service.TemperatureSensor)

describe 'TemperatureAccessory', ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestSensor()
    accessory = new TemperatureAccessory(device)

  describe 'temperature', ->

    it "should return current temperature when get event is fired", ->
      accessory.getService(Service.TemperatureSensor)
        .getCharacteristic(Characteristic.CurrentTemperature)
        .getValue((error, value) ->
          assert error is null
          assert value is 50
        )

    it "should update Characteristic.CurrentTemperature when temperature changes", ->
      valueSet = false
      accessory.getService(Service.TemperatureSensor)
        .getCharacteristic(Characteristic.CurrentTemperature)
        .on 'change', (values) =>
          assert values.oldValue is 0
          assert values.newValue is 30
          valueSet = true
      device.fire()
      assert valueSet

  describe 'humidity', ->

    it "should return current humidity when get event is fired", ->
      accessory.getService(Service.HumiditySensor)
        .getCharacteristic(Characteristic.CurrentRelativeHumidity)
        .getValue((error, value) ->
          assert error is null
          assert value is 20
        )

    it "should update Characteristic.CurrentRelativeHumidity when humidity changes", ->
      valueSet = false
      accessory.getService(Service.HumiditySensor)
        .getCharacteristic(Characteristic.CurrentRelativeHumidity)
        .on 'change', (values) =>
          assert values.oldValue is 0
          assert values.newValue is 40
          valueSet = true
      device.fire()
      assert valueSet

  describe 'lowBattery', ->

    it "should return battery status when get event is fired", ->
      check = (expected) =>
        accessory.getService(Service.TemperatureSensor)
          .getCharacteristic(Characteristic.StatusLowBattery)
          .getValue((error, value) ->
            assert error is null
            assert value is expected
          )
      device._lowBattery = false
      check(Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL)
      device._lowBattery = true
      check(Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW)

    it "should set Characteristic.StatusLowBattery when lowBattery changes", ->
      valueSet = false
      accessory.getService(Service.HumiditySensor)
        .getCharacteristic(Characteristic.StatusLowBattery)
        .on 'change', (values) =>
          assert values.newValue is Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW
          valueSet = true
      device.fire()
      assert valueSet
