Gem::Specification.new do |s|
  s.name = 'amazing'
  s.version = '0.1'
  s.summary = 'An amazing widget manager for an awesome window manager'
  s.files = Dir['lib/**/*.rb'] + Dir['bin/*'] + ['LICENSE']
  s.executables = ['amazing']
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options << '--main' << 'README.rdoc' <<
                    '--charset' << 'utf-8' <<
                    '--inline-source' << '--line-numbers' <<
                    '--webcvs' << 'http://github.com/dag/amazing/tree/master/%s' <<
                    '--title' << 'amazing api'
  s.author = 'Dag Odenhall'
  s.email = 'dag.odenhall@gmail.com'
  s.homepage = 'http://amazing.rubyforge.org'
  s.rubyforge_project = 'amazing'
end
