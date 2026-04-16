# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'H3-CoqueGuide' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for H3-CoqueGuide

  # Google ML Kit for Translation
  pod 'MLKitTranslate', '~> 6.0.0'

  # Gemini AI (si ya lo tienes)
  # pod 'GoogleGenerativeAI', '~> 0.4.0'

end

# Post-install hook to ensure proper configuration
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end