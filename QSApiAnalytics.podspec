Pod::Spec.new do |spec|
  spec.name         = "QSApiAnalytics"
  spec.version      = "1.0.4"
  spec.summary      = "Api打点"
  spec.description  = "Api打点分析"
  spec.homepage     = "https://github.com/fallpine/QSApiAnalytics"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "QiuSongChen" => "791589545@qq.com" }
  spec.ios.deployment_target     = "15.0"
  spec.watchos.deployment_target = "8.0"
  spec.source       = { :git => "https://github.com/fallpine/QSApiAnalytics.git", :tag => "#{spec.version}" }
  spec.swift_version = '5'
  spec.source_files  = "QSApiAnalytics/QSApiAnalytics/Tool/*.{swift}"
  spec.dependency "QSNetRequest"
  spec.dependency "QSIpLocation"
end
