require 'timeout'
module TimeoutFramework
  @processing     = false
  TIMEOUT_OPTIONS = {}
  def timeout(method, options = {:timeout => 1, :default_return => []})
    TIMEOUT_OPTIONS[method] = options
  end

  # this is a callback method provided by ruby
  # there is another method called singleton_method_added, which 
  # we can also make use of
  def method_added(method)
    return if @processing
    @processing = true
    alias_method(:"new_#{method}", method)
    define_method(method) do |*args|
      return self.send("new_#{method}", *args) if TIMEOUT_OPTIONS[method].nil?
      options = TIMEOUT_OPTIONS[method]
      begin
        Timeout.timeout(options[:timeout]) do
          # we can also measure the time here to make it self-adapitve
          time = Time.now
          ret = self.send(:"new_#{method}", *args)
          puts Time.now - time 
        end
      rescue 
        $stderr.puts "#{method} takes too long, cut it off"
        ret = options[:default_return]
      end
      ret
    end
    @processing = false
  end
end

class TimeoutTest
  extend TimeoutFramework
  TimeoutTest.timeout :search, :timeout => 1.5,   :default_return => []
  TimeoutTest.timeout :create, :timeout => 0.5, :default_return => {}
  def delete
    sleep(1)
    puts 'delete succeeded!'
  end
  def search
    puts 'a'
    sleep(1)
    puts "search succeeded!"
    [1]
  end

  def create
    sleep(1)
    {:a => 1}
  end
end

if __FILE__ == $0
  tt = TimeoutTest.new
  puts tt.delete.inspect
  puts tt.search.inspect
  puts tt.create.inspect
end


=begin
output:
  delete succeeded!
  nil
  a
  search succeeded!
  1.008764
  nil
  create takes too long, cut it off
  {}
=end
