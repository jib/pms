use strict;
use YAML;

my $struct = {
    name        => 'Foo::Bar',
    version     => '1.2',
    author      => 'pms@example.com',
    depends     => 'Foo',
    description => 'Implements Foo',
};    

print Dump( $struct );  
  
