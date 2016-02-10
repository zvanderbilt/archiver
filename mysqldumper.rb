#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require 'find'

class DBDumper

Version = 0.8


def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = {}

    opts = OptionParser.new do |opts|
        opts.banner = "Usage: #$0 [options]"
        opts.separator ""
        opts.separator "Specific options:"

      # Cast 'target site' argument to a  object.
        opts.on("-t", "--target TARGET", "Site to backup db for") do |target| 
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
    options = DBDumper.parse(ARGV)
    options

    if options[:name].nil? 
        options[:name] = "#{options[:target]}.sql.bak"
    end

    puts "Hello, #{options[:target]} database shall be dumped to #{options[:dest]} as #{options[:name]}"

    sleep 2


    wpconfig = []
    Find.find(options[:target]) do |path|
      wpconfig = path if path =~ /wp-config\.php$/
      end
    puts wpconfig

    name, user, pass, host = File.read("#{wpconfig}").scan(/'DB_[NAME|USER|PASSWORD|HOST]+'\, '(.*?)'/).flatten
    
    Dir.chdir("#{options[:dest]}")
    puts Dir.pwd

    `mysqldump --opt -u#{user} -p#{pass} -h#{host} #{name} > #{options[:name]}`

    backup = "#{options[:dest]}#{options[:name]}"

    puts "Finished! Checking if #{backup} exists..."
    thetruth = File.exists?(File.expand_path("#{backup}"))
    puts "The existence of #{backup} is #{thetruth}"    
    puts `file #{backup}`

rescue => e
    puts e
end

