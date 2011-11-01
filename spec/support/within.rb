module Within
  def within seconds, what
    raise 'errm, was expected a block to perform condition on' unless block_given?
    start, match, hint = Time.now, false, "[you didnt specify]"
    while (((Time.now - start) < seconds) && !match) do
      match, hint = yield
    end
    raise "Expected #{what}, within #{seconds} second, instead was #{hint}" unless match
  end
end