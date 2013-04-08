module MatchingHelper

  def array_mean(array)
    return nil if array.size == 0
    array.inject(:+).to_f / array.size
  end

  def array_sample_variance(array)
    m = self.array_mean(array)
    sum = array.inject(0){|accum, i| accum +(i-m)**2 }
    sum / (array.length - 1).to_f
  end

  def array_standard_deviation(array)
    return nil if array.size < 2
    return Math.sqrt(self.array_sample_variance(array))
  end

  def array_median(array)
    return nil if array.size == 0
    array = array.sort!
    len = array.size
    len % 2 == 1 ? array[len/2] : (array[len/2 - 1] + array[len/2]).to_f / 2
  end

  def array_max(array)
    array.max #|| 0
  end

  def array_min(array)
    array.min #|| 0
  end

  def array_count(array)
    size = array.size
    size = nil if size == 0
    size
  end

end
