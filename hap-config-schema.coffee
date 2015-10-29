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
      default: "031-45-154"
    port:
      description: "The network port that the bridge is using"
      type: "integer"
      default: 51826
  }
};
