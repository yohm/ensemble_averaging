require 'pp'
require 'fileutils'
require 'optparse'

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

option = { missing_val: nil }
OptionParser.new do |opt|
  opt.on('-f', 'Replace missing values with 0. Set this option for frequency data.') {|v| option[:missing_val] = 0 }
  opt.on('-b', '--binning=BINSIZE', 'Take binning with bin size BINSIZE.') {|v| option[:binning] = v.to_f }
  opt.on('-l', '--log-binning=[BINBASE]', 'Take logarithmic binning with the base of logarithm BINBASE. (default: 2)') {|v| option[:log_binning] = (v or 2).to_f }
  opt.on('-o', '--output=FILENAME', 'Output file name') {|v| option[:outfile] = v }

  opt.parse!(ARGV)
end

raise "-b and -l options are incompatible" if option.has_key?(:binning) and option.has_key?(:log_binning)

p option

