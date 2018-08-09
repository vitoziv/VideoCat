source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'

inhibit_all_warnings!

target 'VideoCat' do
    use_frameworks!

    pod 'MBProgressHUD', '~> 1.0.0'
    pod 'RxSwift', '~> 4.0.0'
    pod 'RxCocoa', '~> 4.0.0'
    pod 'TinyConstraints', '~> 3.0.1'
    
#    pod 'VFCabbage', :path => '../Cabbage'
#    pod 'VIPlayer', :path => '../VIPlayer'
    
    pod 'VIPlayer', :git => 'https://github.com/VideoFlint/VIPlayer.git', :commit => '7b49099'
    pod 'VFCabbage',  :git => 'https://github.com/VideoFlint/Cabbage.git', :commit => '012120d'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'VFCabbage'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
    end
end
