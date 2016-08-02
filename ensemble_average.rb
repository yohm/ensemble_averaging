require 'pp'
require 'fileutils'
require 'optparse'

class Table

  # If we have the following input file
  #   0   x01  x02  x03
  #   1   x11  x12  x13
  #   2   x21  x22  x23
  #   ...
  # The data should be
  #   keys = [0,1,2,...]
  #   columns = [
  #              [x01,x11,x21],
  #              [x02,x12,x22],
  #              [x03,x13,x23],
  #              ...
  #             ]
  #
  attr_accessor :keys, :columns, :errors

  def initialize
    @keys = []
    @columns = nil
    @errors = nil
  end

  def self.load_file(filename)
    data = self.new
    File.open(filename).each do |line|
      next if line =~ /^\#/
      mapped = line.split.map(&:to_f)
      data.keys << mapped[0]
      vals = mapped[1..-1]
      data.columns ||= Array.new( vals.size ) { Array.new }
      vals.each_with_index do |x,col|
        data.columns[col] << x
      end
    end
    data
  end

  def to_s
    sio = StringIO.new
    if @errors
      arrays = @columns.zip( @errors ).flatten(1)
    else
      arrays = @columns
    end
    @keys.zip( *arrays ) do |args|
      sio.puts args.join(' ')
    end
    sio.string
  end

  # take linear binning against data
  # if is_histo is true, normalize the frequency of every bin by its bin size
  # return binned data
  def linear_binning( bin_size, is_histo )
    val_to_binidx = lambda {|v|
      (v.to_f / bin_size).floor
    }
    binidx_to_val = lambda {|idx|
      idx * bin_size
    }
    binidx_to_binsize = lambda {|idx|
      bin_size
    }

    binning( val_to_binidx, binidx_to_val, binidx_to_binsize, is_histo )
  end

  # take logarithmic binning against data
  # if is_histo is true, normalized the frequency of every bin by its bin size
  # return binned data
  def log_binning( bin_base, is_histo )
    val_to_binidx = lambda {|v|
      ( Math.log(v)/Math.log(bin_base) ).floor
    }
    binidx_to_val = lambda {|idx|
      bin_base ** idx
    }
    binidx_to_binsize = lambda {|idx|
      bin_base ** idx
    }

    binning( val_to_binidx, binidx_to_val, binidx_to_binsize, is_histo )
  end

  def self.averaging( tables, is_histo )
    key_unified_tables = unify_keys( tables, is_histo )
    ave = calc_average_error( key_unified_tables )
  end

  private
  def binning( val_to_binidx, binidx_to_val, binidx_to_binsize, is_histo )
    binned_data = self.class.new
    sorted_bin_idxs = @keys.map(&val_to_binidx).uniq.sort
    binned_data.keys = sorted_bin_idxs.map(&binidx_to_val)

    binned_data.columns = @columns.map do |column|
      grouped = Hash.new {|h,k| h[k] = [] }
      @keys.zip( column ) do |key, column|
        bin_idx = val_to_binidx.call(key)
        grouped[bin_idx] << column
      end
      averaged = {}
      grouped.each do |bin_idx,val|
        if is_histo
          averaged[bin_idx] = val.inject(:+) / binidx_to_binsize.call(bin_idx)
        else
          averaged[bin_idx] = val.inject(:+) / val.size
        end
      end
      sorted_bin_idxs.map {|key| averaged[key] || 0 }
    end
    binned_data
  end

  def self.unify_keys( tables, is_histo )
    merged_keys = tables.map(&:keys).flatten.uniq.sort.freeze
    missing_val = is_histo ? 0 : nil

    tables.map do |tab|
      t = Table.new
      t.keys = merged_keys
      t.columns = tab.columns.map do |col|
        merged_keys.map do |k|
          idx = tab.keys.index(k)
          idx ? col[idx] : missing_val
        end
      end
      t
    end
  end

  def self.calc_average_error( tables )
    num_col = tables.first.columns.size
    num_row = tables.first.columns.first.size

    result = self.new
    result.keys = tables.first.keys.dup
    result.columns = Array.new( num_col ) { Array.new( num_row ) }
    result.errors = Array.new( num_col ) { Array.new( num_row ) } if tables.size > 1

    num_col.times do |col_idx|
      num_row.times do |row_idx|
        vals = tables.map {|table| table.columns[col_idx][row_idx] }.compact
        ave, err = calc_average_and_error_from_array( vals )
        result.columns[col_idx][row_idx] = ave
        result.errors[col_idx][row_idx] = err
      end
    end
    result
  end

  def self.calc_average_and_error_from_array( values )
    average = values.inject(:+).to_f / values.size
    variance = values.map {|v| (v - average)**2 }.inject(:+) / values.size
    if values.size > 1
      error = Math.sqrt( variance / (values.size-1) )
    else
      error = 0.0
    end
    return average, error
  end
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

option = { is_histo: false }
OptionParser.new do |opt|
  opt.on('-f', 'Set this option for frequency data. Missing values are replaced with 0.' ) {|v| option[:is_histo] = true }
  opt.on('-b', '--binning=BINSIZE', 'Take binning with bin size BINSIZE.') {|v| option[:binning] = v.to_f }
  opt.on('-l', '--log-binning=[BINBASE]', 'Take logarithmic binning with the base of logarithm BINBASE. (default: 2)') {|v| option[:log_binning] = (v or 2).to_f }
  opt.on('-o', '--output=FILENAME', 'Output file name') {|v| option[:outfile] = v }

  opt.parse!(ARGV)
end

raise "-b and -l options are incompatible" if option.has_key?(:binning) and option.has_key?(:log_binning)

input_tables = ARGV.map {|f| Table.load_file(f) }
if option[:binning]
  input_tables.map! {|table| table.linear_binning( option[:binning], option[:is_histo] ) }
elsif option[:log_binning]
  input_tables.map! {|table| table.log_binning( option[:log_binning], option[:is_histo] ) }
end

if input_tables.size > 1
  calc = Table.averaging( input_tables, option[:is_histo] )
  puts calc.to_s
else
  puts input_tables.first.to_s
end

