grunt = require 'grunt'
assert = require 'assert'
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
  require: (module) ->
    require(module)

GenericAccessory = require("../accessories/genericsensor")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestGeneric extends require('events').EventEmitter
  id: "tesgeneric-id"
  name: "testgeneric"
  config: {}

  _presence: false
  _contact: true
  _water: false
  _carbon: false
  _lux: 100.0
  _fire: false

  _battery: null

  getPresence: () =>
    return Promise.resolve(@_presence)

  getContact: () =>
    return Promise.resolve(@_contact)

  getWater: () =>
    return Promise.resolve(@_water)

  getCarbon: () =>
    return Promise.resolve(@_carbon)

  getLux: () =>
    return Promise.resolve(@_lux)

  getFire: () =>
    return Promise.resolve(@_fire)

  getBattery: () =>
    return Promise.resolve(@_battery)

  fire: () =>
    @emit 'presence', true
    @emit 'contact', false
    @emit 'water', true
    @emit 'carbon', true
    @emit 'lux', 1000
    @emit 'fire', true
    @emit 'battery', 10

  hasAttribute: (name) =>
    return name == 'presence' or
      name == 'contact' or
      name == 'water' or
      name == 'carbon' or
      name == 'lux' or
      name == 'fire' or
      name == 'battery'

describe 'GenericAccessory', ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestGeneric()
    accessory = new GenericAccessory(device)

  describe 'presence', ->

    it "should return current value when get event is fired", ->
      accessory.getService(Service.MotionSensor)
        .getCharacteristic(Characteristic.MotionDetected)
        .getValue((error, value) ->
          assert error is null
          assert value is false
        )

    it "should update characteristics when level changes", ->
      valueSet = false
      accessory.getService(Service.MotionSensor)
        .getCharacteristic(Characteristic.MotionDetected)
        .on 'change', (values) =>
          assert values.newValue is true
          valueSet = true
      accessory.getService(Service.MotionSensor)
        .getCharacteristic(Characteristic.MotionDetected)
        .on 'change', (values) =>
          assert values.oldValue is false
          assert values.newValue is true
          valueSet = true

      device.fire()
      assert valueSet

  describe 'contact', ->

    it "should return current value when get event is fired", ->
      accessory.getService(Service.ContactSensor)
        .getCharacteristic(Characteristic.ContactSensorState)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.ContactSensorState.CONTACT_DETECTED
        )

    it "should update characteristics when level changes", ->
      valueSet = false
      accessory.getService(Service.ContactSensor)
        .getCharacteristic(Characteristic.ContactSensorState)
        .on 'change', (values) =>
          assert values.oldValue is Characteristic.ContactSensorState.CONTACT_DETECTED
          assert values.newValue is Characteristic.ContactSensorState.CONTACT_NOT_DETECTED
          valueSet = true

      device.fire()
      assert valueSet

    it "getContactSensorState should return right value", ->
      assert accessory.getContactSensorState(true) is
        Characteristic.ContactSensorState.CONTACT_DETECTED
      assert accessory.getContactSensorState(false) is
        Characteristic.ContactSensorState.CONTACT_NOT_DETECTED

  describe 'water', ->

    it "should return current value when get event is fired", ->
      accessory.getService(Service.LeakSensor)
        .getCharacteristic(Characteristic.LeakDetected)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.LeakDetected.LEAK_NOT_DETECTED
        )

    it "should update characteristics when level changes", ->
      valueSet = false
      accessory.getService(Service.LeakSensor)
        .getCharacteristic(Characteristic.LeakDetected)
        .on 'change', (values) =>
          assert values.newValue is Characteristic.LeakDetected.LEAK_DETECTED
          valueSet = true

      device.fire()
      assert valueSet

    it "getWaterState should return right value", ->
      assert accessory.getWaterState(true) is
        Characteristic.LeakDetected.LEAK_DETECTED
      assert accessory.getWaterState(false) is
        Characteristic.LeakDetected.LEAK_NOT_DETECTED

  describe 'carbon', ->

    it "should return current value when get event is fired", ->
      accessory.getService(Service.CarbonMonoxideSensor)
        .getCharacteristic(Characteristic.CarbonMonoxideDetected)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.CarbonMonoxideDetected.CO_LEVELS_NORMAL
        )

    it "should update characteristics when level changes", ->
      valueSet = false
      accessory.getService(Service.CarbonMonoxideSensor)
        .getCharacteristic(Characteristic.CarbonMonoxideDetected)
        .on 'change', (values) =>
          assert values.newValue is Characteristic.CarbonMonoxideDetected.CO_LEVELS_ABNORMAL
          valueSet = true

      device.fire()
      assert valueSet

    it "getCarbonState should return right value", ->
      assert accessory.getCarbonState(true) is
        Characteristic.CarbonMonoxideDetected.CO_LEVELS_ABNORMAL
      assert accessory.getCarbonState(false) is
        Characteristic.CarbonMonoxideDetected.CO_LEVELS_NORMAL

  describe 'lux', ->

    it "should return current value when get event is fired", ->
      accessory.getService(Service.LightSensor)
        .getCharacteristic(Characteristic.CurrentAmbientLightLevel)
        .getValue((error, value) ->
          assert error is null
          assert value is 100
        )

    it "should update characteristics when level changes", ->
      valueSet = false
      accessory.getService(Service.LightSensor)
        .getCharacteristic(Characteristic.CurrentAmbientLightLevel)
        .on 'change', (values) =>
          assert values.oldValue is 0.0001
          assert values.newValue is 1000
          valueSet = true

      device.fire()
      assert valueSet

  describe 'fire', ->

    it "should return current value when get event is fired", ->
      accessory.getService(Service.SmokeSensor)
        .getCharacteristic(Characteristic.SmokeDetected)
        .getValue((error, value) ->
          assert error is null
          assert value is Characteristic.SmokeDetected.SMOKE_NOT_DETECTED
        )

    it "should update characteristics when level changes", ->
      valueSet = false
      accessory.getService(Service.SmokeSensor)
        .getCharacteristic(Characteristic.SmokeDetected)
        .on 'change', (values) =>
          assert values.newValue is Characteristic.SmokeDetected.SMOKE_DETECTED
          valueSet = true

      device.fire()
      assert valueSet

    it "getSmokeState should return right value", ->
      assert accessory.getSmokeState(true) is
        Characteristic.SmokeDetected.SMOKE_DETECTED
      assert accessory.getSmokeState(false) is
        Characteristic.SmokeDetected.SMOKE_NOT_DETECTED

  describe 'battery', ->

    it "should return battery status when get event is fired", ->
      check = (expected) =>
        accessory.getService(Service.ContactSensor)
          .getCharacteristic(Characteristic.StatusLowBattery)
          .getValue((error, value) ->
            assert error is null
            assert value is expected
          )
      device._battery = 80
      check(Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL)
      device._battery = 10
      check(Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW)

    it "should set Characteristic.StatusLowBattery when lowBattery changes", ->
      valueSet = false
      accessory.getService(Service.ContactSensor)
        .getCharacteristic(Characteristic.StatusLowBattery)
        .on 'change', (values) =>
          assert values.newValue is Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW
          valueSet = true
      device.fire()
      assert valueSet
