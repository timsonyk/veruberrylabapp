# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'veryberrylab' do
  use_frameworks!

  # Облегченная библиотека Yandex Maps
  pod 'YandexMapsMobile', '4.6.1-lite'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # Xcode 15+ sandboxes run scripts; allow Pods scripts to write generated files
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
