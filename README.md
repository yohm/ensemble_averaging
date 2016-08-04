# What is this?

This is a simple scritp which takes ensemble averaging over the data sets.
Linear-, and logarithmic-binning are also implemented.

# Input data format

The input fomrat should be a simple text file containining x and y data points as follows.

```txt
1 3
2 6
3 36
4 65
5 149
6 235
7 411
8 515
9 721
10 800
11 759
12 743
```

The first column indicates the x-axis and the other columns indicates y-axis data.

Y-axis can be multiple. If there are multiple y-axis, analysis is conducted for each column. See the following.

```txt
0 1 0 1 0 15.4842
0.02 0.9999 0.0001 0.9987 0.0013 15.1745
0.04 0.9997 0.0003 0.9979 0.0021 14.8648
0.06 0.9995 0.0005 0.9971 0.0029 14.5551
0.08 0.9994 0.0006 0.9951 0.0049 14.2455
0.1 0.9992 0.0008 0.9923 0.0077 13.9358
```

# Usage

Specify the input files as command line arguments.
The command will calculate an ensemble average and its error over the 5 data sets.


```sh
ruby ensemble_averaging.rb 1.dat 2.dat 3.dat 4.dat 5.dat
```

If you would like to use the wildcard, use with `xargs`.

```sh
ls *.dat | xargs ruby ensemble_averaging.rb
```

## Options

These are the available command line options.

```
-o, --output=FILENAME            Output file name
-f                               Set this option for frequency data. Missing values are replaced with 0.
-b, --binning=BINSIZE            Take binning with bin size BINSIZE.
-l, --log-binning=[BINBASE]      Take logarithmic binning with the base of logarithm BINBASE. (default: 2)
```

If you would like to take binning on x, then specify `-b BINSIZE` option. To take log-binning, specify `-l`.
These options are useful even you have a single input file.

If you have the data for freqeuncy, specify `-f` option.
Y-values will be normalized by the size of the bins when taking the bin. 
When calculating ensemble averages, y-value whose corresponding x-value is missing in one of the input files are replaced with zero.

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 Yohsuke Murase

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
