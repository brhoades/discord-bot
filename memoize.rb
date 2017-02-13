#http://blog.sgtfloyd.com/post/84242904702
# Decorator to memoize the result of a given function
def memoize(fn, delay=10*60*60)
  cache = {}
  cache_timestamps = {}

  fxn = singleton_class.instance_method(fn)
  define_singleton_method fn do |*args|
    # Remove stale entries
    if cache_timestamps.inclue?(args) and cache_timestamps[args] < Time.now
      cache_timestamps.delete args
      cache.delete args
    end

    unless cache.include?(args)
      cache[args] = fxn.bind(self).call(*args)
      cache_timestamps[args] = Time.now + cache_time
    end
    cache[args]
  end
end
