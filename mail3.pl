use strict;
use warnings;
use MIME::Lite;
use Net::SMTP_auth;


my $from = 'cbuehler@ccboe.com';
my $to = 'cbuehler@ccboe.com';

my           $msg = MIME::Lite->new(
                        From     => 'cbuehler@ccboe.com',
                        To       => 'cbuehler@ccboe.com',
                        Cc       => 'sorpigal@gmail.com',
                        Subject  => 'mail test',
                        Type     => 'text/plain',
                        Encoding => 'base64',
			Data	=> 'test body',
                        );

my $str = $msg->as_string;



my $smtp = Net::SMTP_auth->new('exchange.ccboe.com');
$smtp->auth('LOGIN', &encode_base64('cbuehler'), &encode_base64('c001n3ss'));

$smtp->data();
$smtp->datasend($str);
$smtp->dataend();



    sub encode_base64
{
    my $res = "";
    my $eol = $_[1];
    $eol = "\n" unless defined $eol;
    pos($_[0]) = 0;                          # ensure start at the beginning
    while ($_[0] =~ /(.{1,45})/gs) {
	$res .= substr(pack('u', $1), 1);
	chop($res);
    }
    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    # break encoded string into lines of no more than 76 characters each
    if (length $eol) {
	$res =~ s/(.{1,76})/$1$eol/g;
    }
    $res;
}
__END__
$smtp->mail($from) or die $!;
$smtp->recipient($to,{Notify => ['NEVER']}) or die $!;
#$smtp->to($to); or die $!;

$smtp->data();

$smtp->datasend("Subject: test message\n");
$smtp->datasend("\n");
$smtp->datasend("This is a test");
$smtp->datasend("This is another test");
$smtp->datasend("\nThis is yet another test");
$smtp->dataend();

$smtp->quit();


