require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = "web/public/api"
  rd.title = "amazing api"
  rd.options << '--charset' << 'utf-8' <<
                '--inline-source' << '--line-numbers' <<
                '--webcvs' << 'http://github.com/dag/amazing/tree/master/%s'
end
