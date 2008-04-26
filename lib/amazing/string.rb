# Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
# Licensed under the Academic Free License version 3.0

class String
  def camel_case
    split(/[\s_-]/).map {|t| t[0].chr.upcase + t[1..-1] }.join
  end
end
