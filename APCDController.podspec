Pod::Spec.new do |s|
  s.name             = "APCDController"
  s.version          = "0.1.3"
  s.summary          = "CoreData stack done right."
  s.description      = <<-DESC
                        Simple class containing multithreaded CoreData stack.
                       DESC
  s.homepage         = "https://github.com/Deszip/APCDController"
  s.license          = 'MIT'
  s.author           = { "Deszip" => "igor@alterplay.com" }
  s.source           = { :git => "https://github.com/Deszip/APCDController.git", :tag => s.version.to_s}

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.8'

  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.frameworks = 'CoreData'
end
