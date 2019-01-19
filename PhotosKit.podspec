#
# Be sure to run `pod lib lint PhotosKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PhotosKit'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PhotosKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ws00801526/PhotosKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ws00801526' => '3057600441@qq.com' }
  s.source           = { :git => 'https://github.com/ws00801526/PhotosKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.swift_version    = '4.2'

  s.ios.deployment_target = '9.0'
#  s.source_files = 'PhotosKit/Classes/**/*'

  s.subspec 'Picker' do |ss|
      ss.resource = 'Picker/Assets/**/*'
      ss.source_files = 'Picker/Classes/**/*'
  end
  
  # s.subspec 'Tests' do |ss|
      # ss.source_files = 'Tests/Classes/**/*'
      # ss.dependency 'Quick', '~> 1.2.0'
      # ss.dependency 'Nimble', '~> 7.0.2'
    # ss.requires_app_host = true
    # end

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'Photos'
  # s.dependency 'AFNetworking', '~> 2.3'
end
