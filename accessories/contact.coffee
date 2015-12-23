module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # ContactSensor
  ##
  class ContactAccessory extends BaseAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.ContactSensor, device.name)
        .getCharacteristic(Characteristic.ContactSensorState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getContact(), callback, @getContactSensorState)

      device.on 'contact', (state) =>
        @getService(Service.ContactSensor)
          .setCharacteristic(Characteristic.ContactSensorState, @getContactSensorState(state))

    getContactSensorState: (state) =>
      if state
        return Characteristic.ContactSensorState.CONTACT_DETECTED
      else
        return Characteristic.ContactSensorState.CONTACT_NOT_DETECTED
