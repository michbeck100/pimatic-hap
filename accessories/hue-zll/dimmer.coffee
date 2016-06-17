module.exports = (env) ->

  DimmerAccessory = require('../dimmer')(env)

  ##
  # HueZLLDimmableLight
  ##
  class HueDimmerAccessory extends DimmerAccessory

    constructor: (device) ->
      super(device)
