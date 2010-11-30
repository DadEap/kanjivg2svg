# Encoding: UTF-8

require 'rubygems'
require 'nokogiri'
require 'pp'

class Importer
  class KanjiVG
    
    WIDTH = 120
    HEIGHT = 120
    SVG_HEAD = "<svg width=\"__WIDTH__\" height=\"#{HEIGHT}\" viewBox=\"-5 -5 __WIDTH__ #{HEIGHT}\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xml:space=\"preserve\" version=\"1.1\"  baseProfile=\"full\">"
    SVG_FOOT = '</svg>'
    TEXT_STYLE = 'fill:#FF2A00;font-family:Helvetica;font-weight:normal;font-size:14;stroke-width:0'
    PATH_STYLE = 'fill:none;stroke:black;stroke-width:3'
    ENTRY_NAME = 'kanji'
    COORD_RE = %r{(?ix:\d+ (?:\.\d+)?)}
    
    def initialize(doc, output_dir, type = :numbers, verbose = false)
      @output_dir = output_dir
      @type = type
      @verbose = verbose
      processed = 0

      puts "Starting the conversion @ #{Time.now} ..." if @verbose
      
      # Don't want Nokogiri to read in the entire document at once
      # So doing it entry by entry
      tmp = ""
      begin
        while (line = doc.readline)
          if line =~ %r{<#{ENTRY_NAME}}
            tmp = line
          elsif line =~ %r{</#{ENTRY_NAME}>}
            tmp << line
            noko = Nokogiri::XML(tmp)
            parse(noko)
            
            processed += 1
            if processed % 1000 == 0
              puts "Processed #{processed} @ #{Time.now}" if @verbose
            end
          else
            tmp << line
          end
        end
      rescue EOFError
        doc.close
      end
    end
    
    private
    
    def parse(doc)
      doc.css(ENTRY_NAME).each do |entry|
        codepoint = entry['id']
        svg = File.open("#{@output_dir}/U+#{codepoint}_#{@type}.svg", File::RDWR|File::TRUNC|File::CREAT)
        
        if @type == :frames
          width = WIDTH * entry.css('stroke').length
        else
          width = WIDTH * 1
        end
        header = SVG_HEAD.gsub('__WIDTH__', width.to_s)
        svg << "#{header}\n"
        
        stroke_count = 0
        paths = []
        entry.css('stroke').each do |stroke|
          paths << stroke['path']
          stroke_count += 1
          
          base_path = "<path d=\"#{stroke['path']}\""
          case @type
          when :animated
            svg << "#{base_path} style=\"#{PATH_STYLE};opacity:0\">\n"
            svg << "  <animate attributeType=\"CSS\" attributeName=\"opacity\" from=\"0\" to=\"1\" begin=\"#{stroke_count-1}s\" dur=\"1s\" repeatCount=\"0\" fill=\"freeze\" />\n"
            svg << "</path>\n"
          when :numbers
            x, y = move_text_relative_to_path(stroke['path'])
            svg << "<text x=\"#{x}\" y=\"#{y}\" style=\"#{TEXT_STYLE}\">#{stroke_count}</text>\n"
            svg << "#{base_path} style=\"#{PATH_STYLE}\" />\n"
          when :frames
            md = %r{^[LMT] (#{COORD_RE}) , (#{COORD_RE})}ix.match(paths.last)
            path_start_x = md[1].to_f
            path_start_y = md[2].to_f
            
            paths.each do |path|
              path.gsub!(%r{([LMT]) (#{COORD_RE})}x) do |m|
                letter = $1
                x  = $2.to_f
                x += WIDTH
                "#{letter}#{x}"
              end
              path.gsub!(%r{(S) (#{COORD_RE}) , (#{COORD_RE}) , (#{COORD_RE})}x) do |m|
                letter = $1
                x1  = $2.to_f
                x1 += WIDTH
                x2  = $4.to_f
                x2 += WIDTH
                "#{letter}#{x1}#{$3}#{x2}"
              end
              path.gsub!(%r{(C) (#{COORD_RE}) , (#{COORD_RE}) , (#{COORD_RE}) , (#{COORD_RE}) , (#{COORD_RE})}x) do |m|
                letter  = $1
                x1  = $2.to_f
                x1 += WIDTH
                x2  = $4.to_f
                x2 += WIDTH
                x3  = $6.to_f
                x3 += WIDTH
                "#{letter}#{x1}#{$3}#{x2}#{$5}#{x3}"
              end
              
              svg << "<path d=\"#{path}\" style=\"#{PATH_STYLE}\" />\n"
            end
            svg << "\n"
          end
        end

        svg << SVG_FOOT
        svg.close
      end
    end
    
    # TODO: make this shit really smart
    def move_text_relative_to_path(path)
      md = %r{^M (#{COORD_RE}) , (#{COORD_RE})}ix.match(path)
      path_start_x = md[1].to_f
      path_start_y = md[2].to_f
      
      text_x = path_start_x
      text_y = path_start_y
      
      [text_x, text_y]
    end
    
  end
end

file = ARGV[0]
Importer::KanjiVG.new(File.open(file), File.expand_path('../svgs',  __FILE__), :frames, true)