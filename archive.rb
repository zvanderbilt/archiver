#!/usr/bin/env ruby

require 'optparse'
require 'pp'

class Archiver

Version = 1.0

  CODES = %w[gz bz2 xz]
  CODE_ALIASES = { "gzip" => "gz", "bzip2" => "bz2", "lzma" => "xz" }

def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = { 
       compression: "gz", 
       dest: "~/",
       verbose: false
       }

    opts = OptionParser.new do |opts|
        opts.banner = "Usage: #$0 [options]"
        opts.separator ""
        opts.separator "Specific options:"

      # Cast 'target' argument to a  object.
        opts.on("-t", "--target TARGET", "Backup target(PATH must be absolute") do |target| 
            options[:target] = target
        end

      # Cast 'dest' argument to a  object.
        opts.on("-d", "--dest [DESTINATION]", "Backup Destination") do |dest|
            options[:dest] = dest
        end

      # Cast 'name' argument to a  object.
        opts.on("-n", "--name [NAME]", "Backup name") do |name|
            options[:name] = name
        end

      # Keyword completion.  We are specifying a specific set of arguments (CODES
      # and CODE_ALIASES - notice the latter is a Hash), and the user may provide
      # the shortest unambiguous text.
        code_list = (CODE_ALIASES.keys + CODES).join(',')
        opts.on("-c", "--code [CODE]", CODES, CODE_ALIASES, "Select Compression", "  (#{code_list})") do |compression|
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
   begin
    opts.parse!
   #raise OptionParser::MissingArgument if options[:target].nil?
    mandatory = [:target]                                      
    missing = mandatory.select{ |param| options[param].nil? }   
    unless missing.empty?                                        
        puts "Missing options: #{missing.join(', ')}"
        puts ""
        puts opts                                     
        exit                                           
    end                                                 
   rescue OptionParser::InvalidOption, OptionParser::MissingArgument  
        puts $!.to_s                                                           # Friendly output when parsing fails
        puts opts                                               
        exit                                                        
   end    
    
    options

end  # parse
end  # class

begin
    options = Archiver.parse(ARGV)
    options

    if options[:name].nil? 
        options[:name] = File.basename("#{options[:target]}")
    end

    puts "Hello, #{options[:target]} shall be Archived to #{options[:dest]} as #{options[:name]}.tar.#{options[:compression]} using the following compression type: #{options[:compression]}"
    sleep 2

    tarballed_name = "#{options[:name]}.tar.#{options[:compression]}"
    
    puts "Compressing!"
    `tar cvf#{options[:switch]} #{tarballed_name} #{options[:target]}`
    `mv #{tarballed_name} #{options[:dest]}`
    sleep 2
    deflated = "#{options[:dest]}#{tarballed_name}"
    puts "Finished! Checking if #{deflated} exists..."
    thetruth = File.exists?(File.expand_path(deflated))
    puts "The existence of #{deflated} is #{thetruth}"    
    puts `file #{deflated}`

rescue => e
    puts e
end
