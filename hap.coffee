module.exports = (env) =>

  #import accessories
  ButtonAccessory = require('./accessories/button')(env)
  ContactAccessory = require('./accessories/contact')(env)
  DimmerAccessory = require('./accessories/dimmer')(env)
  GenericAccessory = require('./accessories/genericsensor')(env)
  HueLightAccessory = require('./accessories/hue')(env)
  LightbulbAccessory = require('./accessories/lightbulb')(env)
  LedLightAccessory = require('./accessories/ledlight')(env)
  MilightAccessory = require('./accessories/milight')(env)
  MotionAccessory = require('./accessories/motion')(env)
  PowerSwitchAccessory = require('./accessories/powerswitch')(env)
  ShutterAccessory = require('./accessories/shutter')(env)
  ThermostatAccessory = require('./accessories/thermostat')(env)
  RaspBeeCTAccessory = require('./accessories/raspbeect')(env)

  crypto = env.require 'crypto'
  semver = env.require 'semver'
  path = require 'path'

  hap = require 'hap-nodejs'
  Bridge = hap.Bridge
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/dist/lib/util/uuid')
  _ = require 'lodash'

  class HapPlugin extends env.plugins.Plugin

    knownTemplates: {
      'buttons': ButtonAccessory
      'dimmer': DimmerAccessory
      'huezllonoff': LightbulbAccessory
      'huezlldimmable': DimmerAccessory
      'huezllcolortemp': DimmerAccessory
      'huezllcolor': HueLightAccessory
      'huezllextendedcolor': HueLightAccessory
      'maxcul-heating-thermostat': ThermostatAccessory
      'milight-cwww': LightbulbAccessory
      'milight-rgb': MilightAccessory
      'milight-rgbw': MilightAccessory
      'switch': PowerSwitchAccessory
      'shutter': ShutterAccessory
      'temperature': GenericAccessory
      'contact': ContactAccessory
      'thermostat': ThermostatAccessory
      'led-light': LedLightAccessory
      'presence': MotionAccessory
      'tradfridimmer-dimmer': DimmerAccessory
      'tradfridimmer-rgb': DimmerAccessory
      'tradfridimmer-temp': DimmerAccessory
      'raspbee-dimmer': DimmerAccessory
      'raspbee-ct': RaspBeeCTAccessory
      'raspbee-rgb': HueLightAccessory
      'raspbee-rgbct': HueLightAccessory
      'raspbee-group-rgbct': HueLightAccessory
    }

    accessories: {}

    init: (app, @framework, @config) =>
      env.logger.info("Starting homekit bridge")

      hap.init(path.resolve @framework.maindir, '../../hap-database')

      serialNumber = uuid.generate(@config.name)
      bridge = new Bridge(@config.name, serialNumber)

      bridge.getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "pimatic-hap")
        .setCharacteristic(Characteristic.SerialNumber, serialNumber)
        .setCharacteristic(Characteristic.FirmwareRevision, require('./package.json').version)

      bridge.on 'identify', (paired, callback) =>
        env.logger.debug(@config.name + " identify")
        callback()

      @framework.on 'deviceAdded', (device) =>
        newAccessories = @createAccessoriesFromTemplate(device)

        if newAccessories?
          for accessory in newAccessories
            if accessory? && !accessory.exclude()
              bridge.addBridgedAccessory(accessory)
              if !@accessories.hasOwnProperty(device.id)
                @accessories[device.id] = []
              @accessories[device.id].push accessory
              env.logger.debug("successfully added device " + accessory.displayName)

      @framework.on 'deviceRemoved', (device) =>
        if device.id in @accessories
          bridge.removeBridgedAccessory(entry.id, false) for entry in accessories[device.id]

      @framework.once "after init", =>
        # publish homekit bridge
        env.logger.debug("publishing homekit bridge on port " + @config.port)

        # use default pincode if not already set for backwards compatibility with version 0.12.x
        if !@config.pincode && semver.satisfies(require('./package.json').version, '0.13.0')
          code = '031-45-154'
        else
          generator = new PincodeGenerator()
          code = @config.pincode || generator.generate()
          if generator.isInvalid(code)
            env.logger.error("pincode #{code} is invalid, generating new pincode")
            code = generator.generate()
        env.logger.debug("pincode is: " + code)

        bridge.publish({
          username: @generateUniqueUsername(bridge.displayName),
          port: @config.port,
          pincode: code
          category: Accessory.Categories.BRIDGE
        })
        @config.pincode = code

      @framework.deviceManager.deviceConfigExtensions.push(new HapConfigExtension())

    generateUniqueUsername: (name) =>
      shasum = crypto.createHash('sha1')
      shasum.update(name)
      hash = shasum.digest('hex')

      return "" +
          hash[0] + hash[1] + ':' +
          hash[2] + hash[3] + ':' +
          hash[4] + hash[5] + ':' +
          hash[6] + hash[7] + ':' +
          hash[8] + hash[9] + ':' +
          hash[10] + hash[11]

    createAccessoriesFromTemplate: (device) =>
      newAccessories = []
      if @isKnownDevice(device)
        # special handling for ButtonsDevice with more than one button
        # ButtonsDevice with one Button will fall through and uses old
        # approach like all other devices
        if device.template is "buttons" and device.config.buttons.length > 1
          for b in device.config.buttons
            newAccessories.push new @knownTemplates[device.template](device, b)
          return newAccessories
        #legacy handling to catch ButtonDevices with no button
        if device.template is "buttons" and device.config.buttons.length < 1
          return newAccessories
        #all other devices go here
        newAccessories.push new @knownTemplates[device.template](device)
        return newAccessories
      else if @hasSupportedAttribute(device)
        #generic devices go here
        newAccessories.push new GenericAccessory(device)
        return newAccessories
      else
        env.logger.debug("unsupported device type: " + device.constructor.name)
        return null

    isKnownDevice: (device) =>
      return device.template of @knownTemplates

    hasSupportedAttribute: (device) =>
      for attr in GenericAccessory.supportedAttributes
        if device.hasAttribute(attr)
          return true
      return false

  class HapConfigExtension
    configSchema:
      hap:
        type: "object"
        properties:
          service:
            description: "The homekit service to be used for this device"
            type: "string"
            enum: ["Lightbulb", "Switch"]
            required: false
          exclude:
            description: "Whether to exclude this device from being bridged"
            type: "boolean"
            default: false

    extendConfigShema: (schema) ->
      for name, def of @configSchema
        schema.properties[name] = _.cloneDeep(def)

    applicable: (schema) ->
      return yes

    apply: (config, device) -> # do nothing here

  class PincodeGenerator

    invalid = [
      '000-00-000',
      '111-11-111',
      '222-22-222',
      '333-33-333',
      '444-44-444',
      '555-55-555',
      '666-66-666',
      '777-77-777',
      '888-88-888',
      '999-99-999',
      '123-45-678',
      '876-54-321'
    ]

    generate: () =>
      bytes = crypto.randomBytes(6)
      code = @toString(bytes)
      if @isInvalid(code) then @generate()
      return code

    isInvalid: (code) =>
      return invalid.includes(code)

    toString: (buffer) =>
      return ('000' + buffer.readUInt16LE(0)).substr(-3) + '-' +
        ('00' + buffer.readUInt16LE(2)).substr(-2) + '-' +
        ('000' + buffer.readUInt16LE(4)).substr(-3)

  plugin = new HapPlugin()

  return plugin
