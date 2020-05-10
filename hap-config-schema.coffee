module.exports = {
  title: "Pimatic homekkit bridge config",
  type: "object",
  properties: {
    name:
      description: "The name of the homekit bridge that will be displayed"
      type: "string"
      default: "Pimatic HomeKit Bridge"
    pincode:
      description: "The pincode used to pair the homekit bridge"
      type: "string"
      default: ""
    port:
      description: "The network port that the bridge is using"
      type: "integer"
      default: 51826
    debug:
      description: "Enable debug output"
      type: "boolean"
      default: false
  }
}
