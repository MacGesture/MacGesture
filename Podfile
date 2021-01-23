
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
    
    # Mark the project as it's been checked for distant future Xcode
    xcode_version = '9999'
    installer.pods_project.root_object.attributes['LastSwiftUpdateCheck'] = xcode_version
    installer.pods_project.root_object.attributes['LastUpgradeCheck'] = xcode_version
    # Also delete user data directory from Pods project as schemes contain the version stamp, too
    user_data_path = 'Pods/Pods.xcodeproj/xcshareddata'
    FileUtils.rm_rf user_data_path if File.directory? user_data_path

end
