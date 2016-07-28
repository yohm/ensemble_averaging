require 'pp'
require 'fileutils'

def dat_files
  first_run_dir = Dir.glob("_input/*").first
  dats = Dir.glob(File.join(first_run_dir, "*.dat"))
  dats.map {|dat| File.basename(dat) }
end

def collect_files(filename)
  Dir.glob("_input/*/#{filename}")
end

def load_file(filename)
  parsed = {}
  File.open(filename).each do |line|
    next if line =~ /^\#/
    mapped = line.split.map(&:to_f)
    parsed[ mapped[0] ] = mapped[1..-1]
  end
  parsed
end

def average_error(values)
  average = values.inject(:+).to_f / values.size
  variance = values.map {|v| (v - average)**2 }.inject(:+) / values.size
  if values.size > 1
    error = Math.sqrt( variance / (values.size-1) )
  else
    error = 0.0
  end
  return average, error
end

# set missing_val = nil if you want to ignore the missing value
def calc_average_and_error(files, missing_val)
  datas = files.map {|path| load_file(path) }
  return nil if datas.empty?
  keys = datas.map(&:keys).flatten.uniq.sort
  num_col = datas.first[ datas.first.keys.first ].size

  calculated = {}
  keys.each do |key|
    calculated[key] = []
    num_col.times do |col|
      values = datas.map {|data| data[key] ? data[key][col] : missing_val }.compact
      calculated[key] += average_error(values)
    end
  end
  calculated
end

def output( calculated, outfile )
  outstr = calculated.map {|key,row| key.to_s + ' ' + row.join(' ') }
  if outfile
    File.open(outfile, 'w') do |io|
      io.puts outstr
      io.flush
    end
  else
    $stdout.puts outstr
  end
end


FREQ_FILES.each do |dat|
  analyze(dat, 0.0)
end

CORR_FILES.each do |dat|
  analyze(dat, nil)
end

