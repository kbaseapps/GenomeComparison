use GenomeComparison::GenomeComparisonImpl;

use GenomeComparison::GenomeComparisonServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = GenomeComparison::GenomeComparisonImpl->new;
    push(@dispatch, 'GenomeComparison' => $obj);
}


my $server = GenomeComparison::GenomeComparisonServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
