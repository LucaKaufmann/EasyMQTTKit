#!/bin/bash

find ../xcframework/ -type f -name '*.swiftinterface' -print0 | xargs -0 sed -i '' -e  's/CocoaMQTT\.//'
