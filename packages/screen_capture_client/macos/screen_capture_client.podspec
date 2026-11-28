#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint screen_capture_client.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'screen_capture_client'
  s.version          = '0.0.1'
  s.summary          = 'Screen capture for Showtime using ScreenCaptureKit.'
  s.description      = <<-DESC
Screen capture for Showtime using ScreenCaptureKit.
                       DESC
  s.homepage         = 'https://github.com/luwdm/showtime'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Showtime' => 'https://github.com/luwdm/showtime' }

  s.source           = { :path => '.' }
  s.source_files = 'screen_capture_client/Sources/screen_capture_client/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'screen_capture_client_privacy' => ['screen_capture_client/Sources/screen_capture_client/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'
end
