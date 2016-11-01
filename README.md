[![Build Status](http://img.shields.io/travis/michbeck100/pimatic-hap/master.svg)](https://travis-ci.org/michbeck100/pimatic-hap)
[![Version](https://img.shields.io/npm/v/pimatic-hap.svg)](https://img.shields.io/npm/v/pimatic-hap.svg)
[![downloads][downloads-image]][downloads-url]

[downloads-image]: https://img.shields.io/npm/dm/pimatic-hap.svg?style=flat
[downloads-url]: https://npmjs.org/package/pimatic-hap

pimatic-hap
=======================

pimatic-hap is a [pimatic](https://github.com/pimatic/pimatic) plugin that starts a Homekit Accessory Server and automatically
publishes all devices configured in pimatic as Homekit Accessories using a single Accessory bridge.

Currently it supports most devices that pimatic comes with OOB. Some device types cannot be supported because the HomeKit protocol doesn't have similar types.

The supported devices currently are:
* ButtonsDevice (just the first defined button)
* ContactSensor
* DimmerActuator
* PresenceSensor
* PowerSwitch
* ShutterController
* TemperatureSensor
* HeatingThermostat

These are just base classes, that provide a certain interface, that pimatic-hap understands, but they contain no real logic. All "real" devices, that extend from these, are supported, like [HomeduinoRFSwitch](https://github.com/pimatic/pimatic-homeduino#switch-example). If you want to know if your device is supported, just check the source code of the pimatic plugin. If the device extends from any of the base classes like

      class HomeduinoSwitch extends env.devices.PowerSwitch

then this device is supported.


Apart from the standard devices pimatic-hap supports also devices from third party plugins.
Currently this applies to
* [pimatic-led-light](https://github.com/philip1986/pimatic-led-light) - A pimatic plugin for LED lights resp. LED-Stripes
* [pimatic-hue-zll](https://github.com/markbergsma/pimatic-hue-zll) - Integration of Pimatic with (Zigbee Light Link based) Philips Hue networks, using the Philips Hue (bridge) API.

If you are the developer of a pimatic plugin that defines a new device class, that fits into the HomeKit world, just create a [feature request](https://github.com/michbeck100/pimatic-hap/issues/new).

#### Installation

Since this plugin uses [HAP-NodeJS](https://github.com/KhaosT/HAP-NodeJS), libnss-mdns and libavahi-compat-libdnssd-dev must be installed on a raspberry pi:

    sudo apt-get install libnss-mdns libavahi-compat-libdnssd-dev

To install the plugin just add the plugin to the config.json of pimatic:

    {
      "plugin": "hap"   
    }

This will fetch the most recent version from npm-registry on the next pimatic start and install the plugin.

Please use 031-45-154 as pin, when pairing with the pimatic homekit bridge.

Every iOS app that works with homekit should work with this (like Elgato Eve), so no need for an Apple developer account.

#### Configuration

The configuration of pimatic can be extended by adding an attribute called "hap" on every supported device.
Example:

```json
"devices": [
  {
    "id": "switch",
    "class": "DummySwitch",
    "name": "Switch",
    "hap": {
      "service": "Lightbulb",
      "exclude": true
    }
  }
]

```
To exclude devices from being registered as Homekit Accessory, just set the "exclude" flag to true. By default all supported devices will be registered.

For some devices it's possible to override the default Service (find the explanation of Services [here](https://github.com/KhaosT/HAP-NodeJS#api)).
This is helpful if e.g. a lamp is connected to a pimatic-enabled outlet. Changing the Service to "Lightbulb" will make Homekit recognize the outlet as light, not as switch. This may also change the commands, that one can use with Siri. Currently just switches may act as a light. If you have suggestions for other possible overrides, that make sense, please create a [feature request](https://github.com/michbeck100/pimatic-hap/issues/new).

Since the "hap" attribute doesn't belong to the device config schema, pimatic will issue a warning,
that this is an unknown config entry. Maybe it will be officially possible to extend the configuration. Since then just ignore this warning.


### Sponsoring

Do you like this plugin? Then consider a donation to support development.

<span class="badge-paypal"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=2T48JXA589B4Y" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
[![Flattr pimatic-hap](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=michbeck100&url=https://github.com/michbeck100/pimatic-hap&title=pimatic-hap&language=&tags=github&category=software)

### Changelog

0.8.2
* Reworked shutter implementation to report current state more reliable.
* Moved identify code from switch to lightbulb.
* Just ButtonsDevice with 1 button is supported for now 

0.8.1
* Setting internal state on device state change event and before setting characteristic. This should make switching more robust against infinite loops.

0.8.0
* [#37](https://github.com/michbeck100/pimatic-hap/issues/37)  HomeKit uses 1 and 0 for Characteristic.On, must be converted to bool
* Added Characteristic.StatusLowBattery to temperature and humidity sensor
* removed special hue-zll classes and replaced by simplified versions
* Added implementation for ButtonsDevice. Currently just the first button of a device is supported. Shows up as a normal switch for now, but resets its state after 250 ms.

0.7.0
* Implementation for Philips Hue Lights controlled by pimatic-hue-zll plugin. Currently just features of HueZLLOnOffLight and HueZLLDimmableLight are supported.

0.6.4
* [#21](https://github.com/michbeck100/pimatic-hap/issues/21) Implemented shutter with Service.GarageDoorOpener. This is more like a real shutter than Service.LockMechanism
* Updated to hap-nodejs 0.3.2
* Better debug logging for switches and dimmers

0.6.3
* Added unit tests
* [#29](https://github.com/michbeck100/pimatic-hap/issues/29) Make sure that only if state changed device gets toggled, remember current state of dimmer and switch in local variable, fixing infinite loop for dimmers
* When setting dim level higher than zero switch state gets set to on. This triggered another event which set the dim level to 100.

0.6.1
* Fixed possible null value

0.6.0
* [#20](https://github.com/michbeck100/pimatic-hap/issues/20), [#23](https://github.com/michbeck100/pimatic-hap/issues/23) added config options to exclude devices from homekit and to override service. For now just power switches can be set to Lightbulb instead of Switch.
* Updated hap-nodejs dependency to 0.2.5

0.5.6
* Setting every accessory to reachable by default and logging a warning if the reachability changes.
* Added added error logging if promises throw an error

0.5.5
* Updated hap-nodejs to 0.2.0

0.5.4
* Fixed category of homekit bridge accessory

0.5.3
* Updated hap-nodejs to 0.1.8

0.5.2
* [#9](https://github.com/michbeck100/pimatic-hap/issues/9) setting state when dim level changes
* [#18](https://github.com/michbeck100/pimatic-hap/issues/18) fixed identify for led lights
* [#15](https://github.com/michbeck100/pimatic-hap/issues/15) Added Saturation, so Siri changes colors.
* [#22](https://github.com/michbeck100/pimatic-hap/issues/22) Supporting a min temperature of -50 degrees
* Moved to color-convert as single dependency for color computations.

0.5.1
* Added support for motion sensors

0.5.0
* [#12](https://github.com/michbeck100/pimatic-hap/issues/12) added support for humidity sensors that use the temperature device
* debug logging of hap-nodejs bound to pimatic logger
* [#14](https://github.com/michbeck100/pimatic-hap/issues/14): using turnOn and turnOff methods for switches

0.4.1
* Minor bugfixes

0.4.0
* When setting target temperature, remember the value as current temperature. This is as close as we can get, if device doesn't emit temperature value.
* Notifying iOS devices directly when changing target temperature
* Deleted debug log statements
* determine device type by template, first implementation for BaseLedLight devices
* Added LedLightAccessory

0.3.4
* Ensure that hap database is always at the same place

0.3.3
* Notifying iOS devices actively once temperature changes
* Fixed null check

0.3.2
* [#7](https://github.com/michbeck100/pimatic-hap/issues/7) Explicitly calling method with all parameters

0.3.1
* Updated hap-nodejs dependency to 0.0.7, this changes transitive dependency to node-persist to ^0.0.6
* Fixed error when checking if converter is defined
* Fixed possible infinite loops when device state change triggers iOS notification and notification triggers state change

0.3.0
* [#4](https://github.com/michbeck100/pimatic-hap/issues/4) refactored use of promises
* Fix for restore state at device identify
* updated hap-nodejs dependency to 0.0.6

0.2.2
* contact sensor handling fixed

0.2.1
* [#3](https://github.com/michbeck100/pimatic-hap/issues/3) - fixed error with contact sensor accessory

0.2.0
* support for TemperatureSensor, ContactSensor, HeatingThermostat
* added change notification of iOS devices where possible

0.1.0
* fixed a bug where Homekit Characteristics were not returned correctly

0.0.2
* support for shutters
* implemented identify method for switches, will toggle twice

0.0.1
* initial release
* support for switches and dimmers

### Credit
The original HomeKit API work was done by [KhaosT](http://twitter.com/khaost) in his [HAP-NodeJS](https://github.com/KhaosT/HAP-NodeJS) project.
