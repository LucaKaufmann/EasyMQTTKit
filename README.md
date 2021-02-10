# EasyMQTT Kit

A Framework built around CocoaMQTT, including a few convenience methods to interact with an MQTT broker. Used in the EasyMQTT app.

## Workaround when building
Due to a [Swift bug](https://forums.swift.org/t/frameworkname-is-not-a-member-type-of-frameworkname-errors-inside-swiftinterface/28962/8) you'll get an error when manually building this Framework. The current workaround is to manually remove "CocoaMQTT." from any .swiftinterface files