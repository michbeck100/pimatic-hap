grunt = require 'grunt'
assert = require 'assert'
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
Co2Accessory = require("../accessories/genericsensor")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestSensor extends require('events').EventEmitter
  id: "testsensor-id"
  name: "testsensor"
  config: {}

  _co2: 1000

  getCo2: () =>
    return Promise.resolve(@_co2)

  fire: (value) =>
    @emit 'co2', value

  hasAttribute: (name) =>
    return name == 'co2'

describe 'Co2Accessory', ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestSensor()
    accessory = new Co2Accessory(device)

  describe 'co2', ->

    it "should return current value when get event is fired", ->
      accessory.getService(Service.CarbonDioxideSensor)
        .getCharacteristic(Characteristic.CarbonDioxideLevel)
        .getValue((error, value) ->
          assert error is null
          assert value is 1000
        )

    it "should update characteristics when level changes", ->
      valueSet = false
      accessory.getService(Service.CarbonDioxideSensor)
        .getCharacteristic(Characteristic.CarbonDioxideLevel)
        .on 'change', (values) =>
          assert values.newValue is 1401
          valueSet = true
      accessory.getService(Service.CarbonDioxideSensor)
        .getCharacteristic(Characteristic.CarbonDioxideDetected)
        .on 'change', (values) =>
          assert values.newValue is Characteristic.CarbonDioxideDetected.CO2_LEVELS_ABNORMAL
          valueSet = true

      device.fire(1401)
      assert valueSet

    it "getCarbonDioxideDetected should return right value", ->
      assert accessory.getCarbonDioxideDetected(1400) is
        Characteristic.CarbonDioxideDetected.CO2_LEVELS_NORMAL
      assert accessory.getCarbonDioxideDetected(1401) is
        Characteristic.CarbonDioxideDetected.CO2_LEVELS_ABNORMAL
