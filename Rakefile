# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "COPYING", "lib/**/*.rb")
  rd.rdoc_dir = "web/public/api"
  rd.title = "amazing api"
  rd.options << '--charset' << 'utf-8' <<
                '--inline-source' << '--line-numbers' <<
                '--webcvs' << 'http://github.com/dag/amazing/tree/master/%s'
end
