use strict;
use YAML            qw[LoadFile];
use Data::Dumper;
use File::Basename;
use Cwd;

@ARGV or die 'Need at least one source dir';

my $cwd             = cwd();
my $admindir        = '/tmp/var/lib/dpkg';
my $perldir         = '/tmp/dpkg-proto/perl';
my $fulladmindir    = $perldir.$admindir;

system( qq[ rm -f *.deb] )                  and die "$?";
system( "sudo rm -rf $perldir" )            and die $?;
system( "mkdir -p $fulladmindir " )     and die $?;

system( "mkdir -p $fulladmindir/$_" ) 
    for qw[ alternatives info methods parts updates ];

system( "touch $fulladmindir/$_" )
    for qw[ available diversions status ];

for my $srcdir (@ARGV ) {
    ### XXX can be custom file & nicer object & error checking
    my $struct  = LoadFile( "$srcdir/META.info" ) 
                        or die "Could not read META.info";
                        
    my $pkg     = 'p5-' . $struct->{'name'}; 
    $pkg =~ s/::/-/g;
    my $path    = $pkg .'-'. $struct->{version} . '-' 
                    . $struct->{authority};
    my $name    = $path . '.deb';

    ### copy all the stuff over to another dir
    my $builddir    = 'root-' . basename( $srcdir );

    ### toss out old stuff
    system( qq[ rm -rf $builddir ] )    and die "$?";
    
    ### XXX instead of cp -R, we can read manifest
    {   system( qq[mkdir -p $builddir/$path] )          and die "$?";
        system( qq[ cp -R $srcdir/* $builddir/$path ] ) and die "$?";
        chdir $builddir or die "Could not chdir to $builddir: $!";
    }
    
    ### create the debian control file
    {   system( "mkdir -p DEBIAN" ) and die $?;
        
        open my $fh, ">DEBIAN/control" or die "Could not open control: $!";
        
        
        my $contents = << "EOF";
Package: $name 
Version: $struct->{version}
Section: perl
Architecture: all
Description: $struct->{description};
Maintainer: $struct->{author}
Provides: $pkg, ${pkg}-$struct->{authority}
    
EOF
    #Depends: $struct->{depends}
    
        print $fh $contents;
        close $fh;
    }

    ### setup a postinst handler, as demo
    ### This FAILS -- see the *** BLOCKING ISSUE *** in the notes.txt
    if(0)
        {   open my $fh, ">DEBIAN/postinst" or die "Could not open postinst: $!";

        my $contents = << 'EOF';
#!/usr/bin/perl

print "hello world";

EOF
        print $fh $contents;
        close $fh;
        
        chmod 0755, "DEBIAN/postinst";
    }
    
    ### back to start dir
    chdir $cwd or die $!;

    ### create the debian package
    system( "dpkg-deb -b $builddir $name" ) and die $?;

    ### install the package
    system( "sudo ktrace -d -i dpkg -i --admindir=$fulladmindir --instdir=$perldir $name")
        and die $?;
        
}
