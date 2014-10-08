#
# Be sure to run `pod lib lint APCDController.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "APCDController"
  s.version          = "0.1.0"
  s.summary          = "CoreData stack done right."
  s.description      = <<-DESC
                        Simple class containing multithreaded CoreData stack.
                       DESC
  s.homepage         = "https://github.com/Deszip/APCDController"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Deszip" => "igor@alterplay.com" }
  s.source           = { :git => "https://github.com/Deszip/APCDController.git", :tag => "0.1.0" }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'APCDController' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
