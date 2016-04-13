Pod::Spec.new do |s|
  s.name             = "VOKMockUrlProtocol"
  s.version          = "2.2.0"
  s.summary          = "A url protocol that parses and returns fake responses with mock data."
  s.homepage         = "https://github.com/vokal/VOKMockUrlProtocol"
  s.license          = { :type => "MIT", :file => "LICENSE"}
  s.author           = { "Vokal" => "hello@vokalinteractive.com" }
  s.source           = { :git => "https://github.com/vokal/VOKMockUrlProtocol.git", :tag => s.version.to_s }

  s.ios.deployment_target  = '6.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target  = '10.9'
  s.requires_arc = true

  s.source_files = 'VOKMockUrlProtocol.[hm]'
  s.dependency 'ILGHttpConstants', '~> 1.0.0'
  s.dependency 'VOKBenkode', '~> 0.3'
end
