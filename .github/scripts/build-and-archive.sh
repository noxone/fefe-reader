#!/usr/bin/env bash

set -xeu
set -o pipefail

function finish() {
  ditto -c -k --sequesterRsrc --keepParent "${RESULT_BUNDLE_PATH}" "${RESULT_BUNDLE_PATH}.zip"
  rm -rf "${RESULT_BUNDLE_PATH}"
}

trap finish EXIT

SDK="${SDK:-iphoneos}"
WORKSPACE="${WORKSPACE:-FefeReader.xcworkspace}"
PROJECT="${PROJECT:-FefeReader.xcodeproj}"
SCHEME="${SCHEME:-FefeReader}"
CONFIGURATION=${CONFIGURATION:-Release}

BUILD_DIR=${BUILD_DIR:-.build}
ARTIFACT_PATH=${RESULT_PATH:-${BUILD_DIR}/Artifacts}
RESULT_BUNDLE_PATH="${ARTIFACT_PATH}/${SCHEME}.xcresult"
ARCHIVE_PATH=${ARCHIVE_PATH:-${BUILD_DIR}/Archives/${SCHEME}.xcarchive}
DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-${BUILD_DIR}/DerivedData}
CURRENT_PROJECT_VERSION=${BUILD_NUMBER:-0}
EXPORT_OPTIONS_FILE="BuildConfiguration/ExportOptions.plist"

rm -rf "${RESULT_BUNDLE_PATH}"

#-workspace "${WORKSPACE}" \
#    -sdk "${SDK}" \
#    -parallelizeTargets \
xcrun xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -showBuildTimingSummary \
    -disableAutomaticPackageResolution \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -archivePath "${ARCHIVE_PATH}" \
    -resultBundlePath "${RESULT_BUNDLE_PATH}" \
    CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}" \
    archive

xcrun xcodebuild \
    -exportArchive \
    -exportOptionsPlist "${EXPORT_OPTIONS_FILE}" \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${ARTIFACT_PATH}/${SCHEME}.ipa"

# Zip up the Xcode Archive into Artifacts folder.
ditto -c -k --sequesterRsrc --keepParent "${ARCHIVE_PATH}" "${ARTIFACT_PATH}/${SCHEME}.xcarchive.zip"