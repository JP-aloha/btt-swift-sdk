Pod::Spec.new do |s|
    s.name             = 'BlueTriangleSDK-Swift'
    s.version          = '3.13.1'
    s.summary          = 'BlueTriangleSDK exposes methods to send analytics and crash data to the Blue Triangle portal'
    s.description      = <<-DESC
    BlueTriangleSDK exposes methods to send analytics and crash data to the Blue Triangle portal via HTTP Post
                         DESC

    s.homepage         = 'https://www.bluetriangle.com'
    s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
    s.author           = { 'Blue Triangle SDK Support' => 'sdk-support@bluetriangle.com' }
    s.source           = { :git => 'https://github.com/blue-triangle-tech/btt-swift-sdk.git', :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/_BlueTriangle'

    s.module_name   = 'BlueTriangle'
    s.swift_version = '5.5'

    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.tvos.deployment_target = '13.0'
    s.watchos.deployment_target = '6.0'

    s.source_files = 'Sources/**/*.{swift,c,h,m}'
    s.resource_bundles = {"BlueTriangle" => ["Sources/**/PrivacyInfo.xcprivacy"]}
    
     # Base flavor: no Clarity dependency added.
  
  # Optional subspec for Clarity support.
    s.subspec 'WithClarity' do |ss|
       # If your SDK code doesn't change between flavors, you can leave source_files empty
       # so it reuses the base spec's files.
       # Optionally, you can override settings or add extra files here if needed.
    
       # Add the Clarity dependency. (Make sure Clarity is available as a CocoaPod.)
       ss.dependency 'Clarity', '~> 3.0.0'
       ss.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) WITH_CLARITY' }
    end
  end
