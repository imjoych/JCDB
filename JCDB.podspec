Pod::Spec.new do |s|
  s.name         = 'JCDB'
  s.version      = '0.1.0'
  s.license      = 'MIT'
  s.summary      = 'A useful iOS database framework based on FMDB and SQLite.'
  s.homepage     = 'https://github.com/Boych/JCDB'
  s.author       = { 'ChenJianjun' => 'ioschen@foxmail.com' }
  s.source       = { :git => 'https://github.com/boych/JCDB.git', :tag => s.version.to_s }
  s.source_files = 'JCDB/*.{h,m}'
  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.dependency 'FMDB'

end
