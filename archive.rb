#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require 'find'
require 'wpcli'
require 'uri'

class Opts

Version = 1.0

  CODES = %w[gz bz2 xz lzma]
  CODE_ALIASES = { "gzip" => "gz", "bzip2" => "bz2", "lzma" => "xz" }

def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = { 
       compression: "gz", 
       dest: "/tmp/",
	   target: "./",
	   switch: "z",
       }

    opts = OptionParser.new do |opts|
        opts.banner = "Usage: #$0 [options]"
        opts.separator ""
        opts.separator "Specific options:"

      # Cast 'target' argument to a  object.
        opts.on("-t", "--target TARGET", "Backup target(PATH must be absolute)") do |target| 
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

        code_list = (CODE_ALIASES.keys + CODES).join(',')
        opts.on("-c", "--code [CODE]", CODES, CODE_ALIASES, "Select Compression", "  (#{code_list})") do |compression|
            options[:compression] = compression

            if compression == "gzip"
                switch = "z"
            elsif compression == "bzip2"
                switch = "j"
            elsif compression == "lzma"
                switch = "J"
            end

            options[:switch] = switch
        end

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            options[:verbose] = v
        end

        opts.separator ""
        opts.separator "Common options:"

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

class Archiver

## Initialize options ##
def initialize(options)
	@options = options 
	@target = @options[:target]
    @dest = @options[:dest] 
end

def wp_found(options)
	begin
		puts "Hello, #{@options[:target]} shall be searched to find WP installations..."
		Dir.chdir(@target)
		wpconfigs = Array.new()
		Find.find(@options[:target]) do |path|
			wpconfigs << path if path =~ /\/(wp|local)\-config\.php$/
		end

		wpconfigs.each do |file|
			if file =~ /(bak|repo|archive|backup|safe|db|html\w|html\.)/
				next	
			end
			@wpcli = Wpcli::Client.new File.dirname(file)
			puts "Backing up..." 
			ugly_site_name = @wpcli.run "option get siteurl --allow-root"
			better_site_name = ugly_site_name.to_s.match(URI.regexp)
			site_name = better_site_name.to_s.sub(/^https?\:\/\//, '').sub(/^www./,'')
			puts site_name
			export_sql = @wpcli.run "db export #{site_name}.sql --allow-root"
			export_sql
			@backup_sql = "#{site_name}.sql"
			@backup_target = File.basename(File.dirname(file))
			@backup_parent = File.dirname(File.dirname(file))
			compressor(options,site_name)
		end
	rescue => e
		puts e
	end
end # def

def compressor(options,site_name)
begin
	tarballed_name = "#{site_name}.tar.#{@options[:compression]}"

	puts "Compressing! with the following algorithm: #{@options[:compression]}"
	Dir.chdir(@options[:dest])
	`tar c#{@options[:switch]}vf #{tarballed_name} #{@backup_sql} -C #{@backup_parent} #{@backup_target}` 

	puts "Finished! Checking if #{@options[:dest]}#{@backup_sql} exists..."
	thetruth_sql = File.exist?(File.expand_path("#{@options[:dest]}#{@backup_sql}"))
	puts "The existence of #{@backup_sql} is #{thetruth_sql}"    
	puts "Deleting #{@options[:dest]}#{@backup_sql}..." 
	File.delete(@backup_sql)
	thenewtruth = File.exist?(File.expand_path("#{@options[:dest]}#{@backup_sql}"))
	puts "The existence of #{@backup_sql} is #{thenewtruth}"

	deflated = "#{@options[:dest]}#{tarballed_name}"
	puts "Finished! Checking if #{deflated} exists..."
	thetruth_tar = File.exist?(File.expand_path(deflated))
	puts "The existence of #{deflated} is #{thetruth_tar}"
	puts `file #{deflated}`
rescue => e
	puts e
end
end # def

end # class

### PARSE ###

begin
    options = Opts.parse(ARGV)

	Archiver.new(options).wp_found(options)

rescue => e
    puts e
end
