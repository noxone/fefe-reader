#!/bin/bash

# code from https://engineering.talkdesk.com/test-and-deploy-an-ios-app-with-github-actions-44de9a7dcef6

set -eo pipefail

xcodebuild -project FefeReader.xcodeproj \
            -scheme FefeReader \
            -destination platform=iOS\ Simulator,OS=17.0,name=iPhone\ 15\ Pro \
            clean test | xcpretty
