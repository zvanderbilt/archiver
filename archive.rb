#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require 'find'
require 'mysql'

class Opts

Version = 1.0

  CODES = %w[gz bz2 xz]
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
    
#    wpdirs = Array.new()
#        Find.find(@target) do |path|
#			wpconfigs = File.join("#{@target}", "**", '{wp,local}-config.php')
#			Dir.glob(wpconfigs) do |file|
#        		wpdirs << file if file != /(bak|Bak|repo|archive|Backup|html[\w|\-|\.])/
#        	end
#    	end

#	puts wpdirs
#
#    wpdirs.each do |file|
#		name, user, password, host = File.read(file).scan(/'DB_[NAME|USER|PASSWORD|HOST]+'\, '(.*?)'/).flatten
#        `mysqldump --opt -u#{user} -p#{pass} -h#{host} #{name} > #{@options[:dest]}#{@options[:name]}`
#        compressor
#    end

    wpconfigs = Array.new()
        Find.find(@options[:target]) do |path|
        	wpconfigs << path if path =~ /(wp|local)\-config\.php$/
    	end

		wpconfigs.each do |file|
			if file =~ /(bak|Bak|repo|archive|Archive|Backup|html[\w|\-|\.|\_])/
				next	
			end
			name, user, password, host = File.read(file).scan(/'DB_[NAME|USER|PASSWORD|HOST]+'\, '(.*?)'/).flatten
			sitename = get_site_name(name, user, password, host)
			`mysqldump --opt -u#{user} -p#{password} -h#{host} #{name} > #{@options[:dest]}#{sitename}.sql`
			@backup_sql = "#{sitename}.sql"
			@backup_target = File.basename(File.dirname(file))
			@backup_parent = File.dirname(File.dirname(file))
			compressor(options,sitename)
		end


rescue => e
    puts e
end

end # def

def get_site_name(db_name, db_user, db_pass, db_host)
    begin
    con = Mysql.new(db_host, db_user, db_pass}, db_name)
    rs = con.query('SHOW TABLES LIKE "%_options"')
    options_name = rs.fetch_row[0]
    
    rs = con.query('SELECT option_value FROM #{options_name} WHERE option_id = 1')
    return rs.fetch_row[0].gsub(/^https?\:\/\/(www.)?/,'')

    rescue => e
        puts e
    end
ensure
    con.close if con
end

def compressor(options,sitename)
begin
	tarballed_name = "#{sitename}.tar.#{@options[:compression]}"

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
