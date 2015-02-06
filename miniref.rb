#!/usr/bin/env ruby -w
# coding: utf-8

# this is a simplified reimplementation of Lotterlebens miniref
# https://github.com/Lotterleben/miniref
# which is a really nice idea.

require 'optparse'


def number_refs(text)

  # we do not want to touch anything within the signature
  # so we keep it separated
  
  body, sig = text.split(/(?=\n-- \n)/, 2)

  # we a searching for an empty line followed by a line
  # starting with [^....] (which may be indented) to find
  # the beginning of the bib-section.
  
  _, indent, bib = body.split(/(?=\n\n([ \t]*)\[\^[^\]\n]+\])/, 2)

  unless bib
    warn "No bib section found"
    bib = ""
  end


  # We first process bib to generate the numbering
  # as we want the bib to be sorted.
  # We want to allow a citation to refer to further citations
  # therefore we assume all citations are at the beginning of a new line
  # and aligned (i.e. equally indented).

  # we collect all the references in a hash and give a default return
  # for unmatched refs
  refs = Hash.new { |h,k|
    warn "Found unmatched reference [#{k}]"
    "#{k} UNMATCHED"
  }

  counter = 0
  bib.scan(/^#{indent}\[(\^[^\]\n]+)\]/m) { refs[$1] = "#{counter += 1}" }
  
  # now we have a list of keys and replacements and we can proceed
  # the whole body

  body.gsub!(/\[(\^[^\]\n]+)\]/) { "[#{refs[$1]}]" }

  # append the signature again, and we are ready

  return body + (sig || '')

end


# ok, the boring option parsing and file handling…

def main

  # command line parsing
  options = {}
  optparse = OptionParser.new do |opts|

    # Set a banner, displayed at the top of the help screen.
    opts.banner = "Usage: miniref.rb [file]"

    opts.on( '-i', '--infile FILE', 'Read from FILE' ) do |file|
      options[:infile] = file
    end

    opts.on( '-o', '--outfile FILE', 'Write to FILE' ) do |file|
      options[:outfile] = file
    end
 
    # This displays the help screen
    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end
 
  optparse.parse!

  infilename = options[:infile] || ARGV.shift || '-'
  outfilename = options[:outfile] || infilename

  unless ARGV.empty?
    warn "unexpected parameters: #{ARGV.join(', ')}"
    warn "see miniref.rb -h for help"
    exit 1
  end

  begin
    # read the text from file or stdin
    text = if infilename == '-'
             $stdin.read
           else
             File.read(infilename)
           end
  rescue # we could do more sophisticated error handling …
    warn "Error reading from #{infilename}"
    exit 2
  end

  # do the work
  result = number_refs(text) 

  begin
    if outfilename == '-'
      print result
    else
      File.open(outfilename, 'w') { |f| f << result }
    end
  rescue # we could do more sophisticated error handling …
     warn "Error writing #{outfilename}"
    exit 3
  end

end

if $0 == __FILE__
  main
end
