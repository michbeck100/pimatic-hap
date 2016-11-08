module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DefaultAccessory = require('./default')(env)

  ##
  # ContactSensor
  ##
  class ContactAccessory extends DefaultAccessory

    constructor: (device) ->
      super(device, Service.ContactSensor)

      @service
        .getCharacteristic(Characteristic.ContactSensorState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getContact(), callback, @getContactSensorState)

      device.on 'contact', (state) =>
        @service
          .setCharacteristic(Characteristic.ContactSensorState, @getContactSensorState(state))

    getContactSensorState: (state) =>
      if state
        return Characteristic.ContactSensorState.CONTACT_DETECTED
      else
        return Characteristic.ContactSensorState.CONTACT_NOT_DETECTED
