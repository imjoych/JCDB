Pod::Spec.new do |s|
  s.name         = 'JCDB'
  s.version      = '1.0.0'
  s.license      = 'MIT'
  s.summary      = 'A lightweight iOS database framework based on FMDB and SQLite.'
  s.homepage     = 'https://github.com/imjoych/JCDB'
  s.author       = { 'ChenJianjun' => 'imjoych@gmail.com' }
  s.source       = { :git => 'https://github.com/imjoych/JCDB.git', :tag => s.version.to_s }
  s.source_files = 'JCDB/*.{h,m}'
  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.dependency 'FMDB'

end
