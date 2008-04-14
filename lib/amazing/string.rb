class String
  def camel_case
    split(/[\s_-]/).map {|t| t[0].chr.upcase + t[1..-1] }.join
  end
end
