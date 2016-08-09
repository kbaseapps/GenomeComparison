use GenomeComparisonSDK::GenomeComparisonSDKImpl;

use GenomeComparisonSDK::GenomeComparisonSDKServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = GenomeComparisonSDK::GenomeComparisonSDKImpl->new;
    push(@dispatch, 'GenomeComparisonSDK' => $obj);
}


my $server = GenomeComparisonSDK::GenomeComparisonSDKServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
