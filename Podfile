
platform :osx, '10.13'

use_frameworks!

target 'MacGesture' do
  pod 'DBPrefsWindowController'
  pod 'ShortcutRecorder', :git => 'https://github.com/Kentzo/ShortcutRecorder', :branch => 'master'
  pod 'Sparkle'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.11'
    end
  end
end
