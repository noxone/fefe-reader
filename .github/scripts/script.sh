

xcodebuild -project FefeReader.xcodeproj -scheme FefeReader -sdk iphoneos -configuration Release clean

xcodebuild -project FefeReader.xcodeproj -scheme FefeReader -sdk iphoneos -configuration Release archive -archivePath "../build/FefeReader.xcarchive"

xcodebuild -exportArchive -archivePath ../build/FefeReader.xcarchive -exportOptionsPlist exportOptions.plist -exportPath "../build" -allowProvisioningUpdates


