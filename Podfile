# Uncomment the next line to define a global platform for your project
platform :ios, '17.0'

target 'Neck Hump Reset' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Google ML Kit for Pose Detection - much better for side profile poses
  pod 'GoogleMLKit/PoseDetectionAccurate', '~> 7.0'

end

post_install do |installer|
  # Remove excluded architectures from aggregate xcconfig files so simulators work on Apple Silicon
  installer.generated_aggregate_targets.each do |aggregate_target|
    aggregate_target.xcconfigs.each do |config_name, config|
      config.attributes.delete('EXCLUDED_ARCHS[sdk=iphonesimulator*]')
      xcconfig_path = aggregate_target.xcconfig_path(config_name)
      config.save_as(xcconfig_path)
    end
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      # Fix for Xcode 15+ sandbox rsync issues
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      # Suppress warnings in pods (double-quoted include errors)
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
      # Fix for quoted includes in framework headers
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      # Remove excluded architectures so simulators work on Apple Silicon
      config.build_settings.delete('EXCLUDED_ARCHS[sdk=iphonesimulator*]')
    end
  end
end
