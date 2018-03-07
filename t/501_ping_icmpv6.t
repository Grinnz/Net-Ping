# Test to perform ICMPv6 protocol testing.
# Root access is required.
# In the core test suite it calls itself via sudo -n (no password) to test it.

use strict;
use Config;
use Net::Ping;
use Test::More;

BEGIN {
  unless (eval "require Socket") {
    plan skip_all => 'no Socket';
  }
  unless ($Config{d_getpbyname}) {
    plan skip_all => 'no getprotobyname';
  }
  if (!Net::Ping::_isroot()) {
    my $file = __FILE__;
    my $lib = $ENV{PERL_CORE} ? '-I../../lib' : '-Mblib';
    # -n prevents from asking for a password. rather fail then
    # A technical problem is with leak-detectors, like asan, which
    # require PERL_DESTRUCT_LEVEL=2 to be set in the root env.
    if (system("sudo -n PERL_DESTRUCT_LEVEL=2 \"$^X\" $lib $file") == 0) {
      exit;
    } else {
      plan skip_all => 'no sudo/failed';
    }
  }
}

SKIP: {
  skip "icmpv6 ping requires root privileges.", 1
    if !Net::Ping::_isroot() or $^O eq 'MSWin32';
  my $p = new Net::Ping "icmpv6";
  my $rightip = "2001:4860:4860::8888"; # pingable ip of google's dnsserver
  my $wrongip = "2001:4860:4860::1234"; # non existing ip
  # diag "Pinging existing IPv6 ";
  my $result = $p->ping($rightip);
  if ($result == 1) {
    ok($result, "icmpv6 ping $rightip");
    # diag "Pinging wrong IPv6 ";
    ok(!$p->ping($wrongip), "icmpv6 ping $wrongip");
  } else {
  TODO: {
      local $TODO = "icmpv6 firewalled?";
      is($result, 1, "icmpv6 ping $rightip");
    }
  }
}

done_testing;
