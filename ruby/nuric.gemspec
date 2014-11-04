Gem::Specification.new do |s|
  s.name = 'nuric'
  s.version = File.read("#{File.dirname(__FILE__)}/../VERSION").strip
  s.date = File.atime("#{File.dirname(__FILE__)}/../VERSION").strftime('%Y-%m-%d').to_s
  s.summary = 'Nuri Language Compiler'
  s.description = 'A Ruby wrapper of Nuri language compiler'
  s.authors = ['Herry']
  s.email = 'herry13@gmail.com'

  s.executables << 'nuric'

  s.files = `git ls-files`.split("\n")
  s.files << 'lib/nuric/nuric'

  s.require_paths = ['lib']
  s.license = 'Apache-2.0'

  s.homepage = 'https://github.com/nurilabs/nuri-lang'

  s.add_development_dependency 'rake'
end  
