#!/usr/bin/env perl

use strict;
use REST::Client;
use Data::Printer;
use JSON::Parse 'parse_json';
use MIME::Base64;
use List::Flatten;

use constant AUTH_HEADER => "Basic " . encode_base64($ARGV[0] . ':' . $ARGV[1]);
 
my @products = ();
my $client = REST::Client->new();
 
sub processed_rels {
  my $line = qq(@_);
  my @links = split(",", $line);
  my %hash_refs = ();
  foreach my $link (@links) {
    my ($href, $name) = $link =~ /<(.+)>; rel="(\w+)"/igs;
    $hash_refs{$name} = $href;
  }
  return %hash_refs;
}

$client->addHeader('Authorization', AUTH_HEADER);
$client->GET('https://scc.suse.com/connect/organizations/products/unscoped');
 
while (1) {
  my @parsed_products = parse_json($client->responseContent());
  push @products, @parsed_products;
  my %rels = processed_rels($client->responseHeader('Link'));
  last unless $rels{"next"};
  $client->GET($rels{"next"});
}
 
@products = flat @products;

foreach my $product (@products) {
  print $product->{"name"} . "\n";
}
