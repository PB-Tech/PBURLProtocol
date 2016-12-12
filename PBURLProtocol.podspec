Pod::Spec.new do |s|
  s.name         = "PBURLProtocol"
  s.version      = "0.1.0"
  s.summary      = "PBURLProtocol"
  s.homepage     = "https://github.com/PB-Tech/PBURLProtocol"

  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author       = { "PB-Tech" => "pbyte.technology@gmail.com" }

  s.source       = { :git => "https://github.com/PB-Tech/PBURLProtocol.git", :tag => "0.1.0" }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.8'
  s.frameworks = 'Foundation'

  s.source_files = 'src/**/*.{m,h}'
  s.public_header_files = 'src/**/*.h'

  s.requires_arc = true
  s.dependency 'CocoaSecurity'
end
