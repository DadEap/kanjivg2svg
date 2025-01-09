kanjivg2svg
===========

This Ruby script takes stroke order data from the [KanjiVG](http://kanjivg.tagaini.net/) project and outputs SVG files with special formatting.

This script works for ruby 3.3.6. It requires the package nokogiri.

	$ gem install nokogiri

I modified the script to have the symbol as filename in order to easily create anki cards later.

Usage
-----

    $ ruby kanjivg2svg.rb <path/to/kanji> [frames|animated|numbers]

You can change the output type by setting the second argument. If not set it will default to 'frames'. The animated and numbers are less perfected compared to the frames output.

In this repo I've included svg files generated with the 'frames' option.

License
-------

By Kim Ahlström <kim.ahlstrom@gmail.com>

[Creative Commons Attribution-Share Alike 3.0](http://creativecommons.org/licenses/by-sa/3.0/)

KanjiVG
-------

KanjiVG is copyright (c) 2009/2010 Ulrich Apel and released under the Creative Commons Attribution-Share Alike 3.0
