#!/usr/bin/env ruby

require 'optparse'
require 'pp'

class Archiver

Version = 1.0

  CODES = %w[gzip bzip2 lzma zip]
  CODE_ALIASES = { "gz" => "gzip", "bz2" => "bzip2", "xz" => "lzma" }

def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = { 
       compression: "gz", 
       target: Dir.pwd + "/nil", 
       dest: "~/",
       name: "backup.tar.compressed", # canned name, come up with better solution to append compression type but still respect user input
       verbose: false
       }

    opts = OptionParser.new do |opts|
        opts.banner = "Usage: #$0 [options]"
        opts.separator ""
        opts.separator "Specific options:"

      # Cast 'target' argument to a  object.
        opts.on("-t TARGET", "--target", "Backup target(PATH must be absolute") do |target| 
            options[:target] = target
        end

      # Cast 'dest' argument to a  object.
        opts.on("-d DESTINATION", "--dest", "Backup Destination") do |dest|
            options[:dest] = dest
        end

      # Cast 'name' argument to a  object.
        opts.on("-n NAME", "--name", "Backup name") do |name|
            options[:name] = name
        end

      # Keyword completion.  We are specifying a specific set of arguments (CODES
      # and CODE_ALIASES - notice the latter is a Hash), and the user may provide
      # the shortest unambiguous text.
        code_list = (CODE_ALIASES.keys + CODES).join(',')
        opts.on("-c CODE", "--code CODE", CODES, CODE_ALIASES, "Select Compression", "  (#{code_list})") do |compression|
            options[:compression] = compression

            switch = nil

            if compression == "gzip"
                switch = "z"
            elsif compression == "bzip2"
                switch = "j"
            elsif compression == "lzma"
                switch = "J"
            end

            options[:switch] = switch
        end

        # Boolean switch.
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            options[:verbose] = v
        end

        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
        end

        opts.on_tail("-V", "--version", "Show version") do
            puts Version
            exit
        end
    end

    opts.parse!(args)
    options

end  # parse
end  # class

begin
    options = Archiver.parse(ARGV)
    pp options

    puts "Current working directory is #{Dir.pwd}"
#    puts options[:target], options[:dest], options[:name], options[:compression], options[:switch]
    puts "Hello, #{options[:target]} shall be Archived to #{options[:dest]} as #{options[:name]}.tar.#{options[:compression]} " 
    puts "using the following compression type: #{options[:compression]}"
    sleep 2
    puts "Compressing!"
    sleep 5
    `tar cvf#{options[:switch]} #{options[:name]} #{options[:target]}`
	`mv #{options[:name]} #{options[:dest]}`
    sleep 2
    deflated = "#{options[:dest]}#{options[:name]}"
    puts "Finished! Checking if #{deflated} exists..."
    puts File.exists?("#{deflated}") 
    puts `file #{deflated}`

rescue => e
    puts e
end
