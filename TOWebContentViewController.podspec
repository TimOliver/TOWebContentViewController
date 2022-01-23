Pod::Spec.new do |s|
  s.name     = 'TOWebContentViewController'
  s.version  = '1.0.2'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A view controller for displaying arbitrary local HTML content.'
  s.homepage = 'https://github.com/TimOliver/TOWebContentViewController'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOWebContentViewController.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.platform = :ios, '9.0'
  s.source_files = 'TOWebContentViewController/**/*.{h,m}'
  s.resource_bundles = {
    'TOWebContentViewControllerBundle' => ['TOWebContentViewController/**/*.lproj']
  }
end
