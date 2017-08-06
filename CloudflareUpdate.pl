#!/usr/bin/perl

# @author Peter Kappelt
# @version 1.0

use strict;
use warnings;

use JSON;
use LWP::Simple;
use WWW::Curl;
use Data::Dumper;

### Configuration
#The email of your cloudflare account
my $cf_email = 'your-email';

#An API key you need to generate in the Cloudflare dashboard
my $cf_apikey = 'your-apikey';

#The ID of the Zone you want to update. Is on the Cloudflare dashboard
my $cf_zoneid = 'your-zoneid';

#Domains that shall be updated
my @cf_domains = (
					"domain1.com",
					"sub1.domain1.com",
					);

#Path for a cache textfile -> can be any new file that is writeable
my $cache_file = '/var/cache/CloudflareUpdate.cache';

#open the cache file
sub cacheOpen($){
	my $cache_fh;
	open($cache_fh, "$_[0]$cache_file") or die "Can't open cache: $!";
	return $cache_fh;
}

#close the cache file
sub cacheClose($){
	close($_[0]) or die "Can't close cache: $!";
}

#get the last ip that was cached
sub cachedIPGet(){
	if(! (-f $cache_file)){
		my $fh = cacheOpen(">");
		close($fh);
	}
	my $fh = cacheOpen("<");
	
	my $cachedip = readline($fh);
	$cachedip = '' unless defined $cachedip;
	
	cacheClose($fh);
	
	return $cachedip;
}

#write the current ip to the cache
sub cachedIPWrite($){
	my $fh = cacheOpen(">");
	print $fh $_[0];
	cacheClose($fh); 
}

#get the public IP. Currently, only checkip.dyndns.org is supported
sub getPublicIP(){
	my $webresponse = get('http://checkip.dyndns.org');
	die "Error while getting public IP from checkip.dyndns.org. Exiting...\n" unless defined $webresponse;
	
	$webresponse =~ s/.*Current IP Address: ([\d.]+).*/$1/;
	$webresponse =~ s/\r//;
	$webresponse =~ s/\n//;
	return $webresponse;
}

#update the cloudflare domains to a given ip
sub updateCloudflare($){
	my ($ip) = @_;
	
	my $list = `curl -sS -X GET "https://api.cloudflare.com/client/v4/zones/$cf_zoneid/dns_records?type=A" -H "X-Auth-Email: $cf_email" -H "X-Auth-Key: $cf_apikey" -H "Content-Type: application/json"`;
	$list = JSON->new->utf8->decode($list); 
	
	if(int(@{$list->{errors}}) > 0){
		print(localtime() . ": " . "Error while fetching hosts!\n");
		return 0;
	}
	
	#update each host
	foreach my $host(@cf_domains){
		#search for the host id
		#Todo there is a better way
		my $recordid = '';
		foreach my $key (@{$list->{'result'}}){
			if($key->{'name'} eq $host){
				$recordid = $key->{'id'};
			}
		}
		if($recordid eq ''){
			print(localtime() . ": " . "Unknown domain: $host\n");
			next;
		}
		my $host_response = `curl -sS -X PUT "https://api.cloudflare.com/client/v4/zones/$cf_zoneid/dns_records/$recordid" -H "X-Auth-Email: $cf_email" -H "X-Auth-Key: $cf_apikey" -H "Content-Type: application/json" --data '{"type":"A","name":"$host","content":"$ip"}'`;
		$host_response = JSON->new->utf8->decode($host_response);
		if(!$host_response->{success}){
			print(localtime() . ": " . "Error while updating host $host. Response: " . Dumper($host_response) . "\n");
		}else{
			print(localtime() . ": " . "Successfully updated $host\n");
		}
	}
	
	return 1;
}

my $cachedIP = cachedIPGet();
my $currentIP = getPublicIP();

if($currentIP eq $cachedIP){
	#the current ip was already stored to the cache, thus written to cloudflare.
	#No more action needed -> exit
	exit 0;
}

print(localtime() . ": " . "Updating records to new IP $currentIP ...\n");

#set to 1 if there was a successful dns update
my $dnsUpdateSuccess = updateCloudflare($currentIP, );


if($dnsUpdateSuccess){
	cachedIPWrite($currentIP);
}
