#Archiver.rb  
Basic USAGE 

USAGE:
./archive.rb [options]

Specific options:
    -t, --target TARGET              Backup target(PATH must be absolute
    -d, --dest DESTINATION           Backup Destination
    -n, --name NAME                  Backup name
    -c, --code CODE                  Select Compression
                                       (gz,bz2,xz,gzip,bzip2,lzma,zip)
    -v, --[no-]verbose               Run verbosely

Common options:
    -h, --help                       Show this message
    -V, --version                    Show version


EXAMPLE:

./archive.rb -t testdir/ -d /tmp/ -n backup -c lzma -v 
