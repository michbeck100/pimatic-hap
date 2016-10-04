module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service

  SwitchAccessory = require('./switch')(env)

  ##
  # Lightbulb
  ##
  class LightbulbAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

    getDefaultService: ->
      return Service.Lightbulb

    # default identify method on switches turns the switch on and off two times
    identify: (device, paired, callback) =>
      # make sure it's off, then turn on and off twice
      promise = device.getState()
        .then( (state) =>
          device.turnOff()
          .then( => device.turnOn() )
          .then( => device.turnOff() )
          .then( => device.turnOn() )
          .then( =>
            # recover initial state
            device.turnOff() if not state
          )
        )
      @handleVoidPromise(promise, callback)
