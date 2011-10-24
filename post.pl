#!/usr/bin/perl
use strict;
use warnings;

use WWW::Mechanize;

sub GetPassword() {
	my $i=0;
	my @pass;
	my $passfile="./vim_passfile"; # line1: username, line2: password
	open(PASS, '<',$passfile) or die "Can't open passwordfile: $passfile\n";
	while(<PASS>){
		chomp;
		$pass[$i++] = $_;
	}
	close(PASS);
	return @pass;
}

my $sid=3075;
my $file;
my @files=glob('*.vmb');
#my $scriptversion=shift @ARGV;
my $scriptversion = 0;
my $versioncomment=shift @ARGV;
unless ($versioncomment){
	print "Please enter comment!\n";
	exit;
}
$versioncomment.="\n(automatically uploaded)";


my @userpasswordpair = GetPassword();
for (@files) {
	my $f = $_ if [ -f $_ ] && $_ =~ /\w+-[^.]+\.(\d+)\.vmb/;
	if ($1 > $scriptversion) {
		$scriptversion=$1;
		$file = $f;
	}
}

my $mech=WWW::Mechanize->new(autocheck => 1);
$mech->get("http://www.vim.org/login.php");
$mech->submit_form(
    form_name => "login",
    with_fields => {
        userName => $userpasswordpair[0],
        password => $userpasswordpair[1],
    },
);
$mech->get("http://www.vim.org/scripts/script.php?script_id=$sid");
$mech->follow_link(text => 'upload new version');
$mech->form_name("script");
$mech->field(script_file => $file);
$mech->field(vim_version => 7.3);
$mech->field(script_version => $scriptversion);
$mech->field(version_comment => $versioncomment);
$mech->click_button(value => "upload");
