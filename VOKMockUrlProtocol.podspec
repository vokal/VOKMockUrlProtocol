Pod::Spec.new do |s|
  s.name         = "VOKMockUrlProtocol"
  s.version      = "1.0.1"
  s.platform     = :ios
  s.ios.deployment_target = "6.0"
  s.summary      = "A url protocol that parses and returns fake responses with mock data."
  s.homepage     = "https://github.com/vokalinteractive/VOKMockUrlProtocol"
  s.license      = { :type => "MIT", :file => "LICENSE"}
  s.author       = { "VOKAL Interactive" => "hello@vokalinteractive.com" }
  s.source       = { :git => "https://github.com/vokalinteractive/VOKMockUrlProtocol.git", :tag => "1.0.1" }
  s.source_files = "*.{h,m}"
  s.requires_arc = true
  s.dependency 'ILGHttpConstants', '~> 1.0.0'
end
