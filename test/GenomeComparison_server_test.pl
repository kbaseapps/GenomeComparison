use strict;
use Data::Dumper;
use Test::More;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::AuthToken;
use Bio::KBase::workspace::Client;
use GenomeComparison::GenomeComparisonImpl;

local $| = 1;
my $token = $ENV{'KB_AUTH_TOKEN'};
#$ENV{'KB_DEPLOYMENT_CONFIG'} = "/Users/chenry/code/GenomeComparison/localdeploy.cfg";
my $config_file = $ENV{'KB_DEPLOYMENT_CONFIG'};
my $config = new Config::Simple($config_file)->get_block('GenomeComparison');
my $ws_url = $config->{"workspace-url"};
my $ws_name = undef;
my $ws_client = new Bio::KBase::workspace::Client($ws_url,token => $token);
my $auth_token = Bio::KBase::AuthToken->new(token => $token, ignore_authrc => 1);
my $ctx = LocalCallContext->new($token, $auth_token->user_id);
$GenomeComparison::GenomeComparisonServer::CallContext = $ctx;
my $impl = new GenomeComparison::GenomeComparisonImpl();

sub get_ws_name {
    if (!defined($ws_name)) {
        my $suffix = int(time * 1000);
        $ws_name = 'test_GenomeComparison_' . $suffix;
        $ws_client->create_workspace({workspace => $ws_name});
    }
    return $ws_name;
}

eval {
	print STDERR "Loading genome and contigs ...\n";
	
        my $mg_contigs = "kb|g.490.c.0";
	open (CONTIG, "kb_g.490.contigset.json");
        my $obj = <CONTIG>;
	chomp $obj;
	close CONTIG;
	my $decoded = JSON::XS::decode_json($obj);
        $ws_client->save_objects({'workspace' => get_ws_name(), 'objects' => [{'type' => 'KBaseGenomes.ContigSet', 'name' => $mg_contigs, 'data' => $decoded}]});

	my $mg_genome = "Mg";
	open (GENOME, "Mycoplasma_genitalium_G_37.json");
        my $obj2 = <GENOME>;
	chomp $obj2;
	close GENOME;
	my $decoded2 = JSON::XS::decode_json($obj2);
	$decoded2->{"contigset_ref"} = get_ws_name()."/".$mg_contigs;
        $ws_client->save_objects({'workspace' => get_ws_name(), 'objects' => [{'type' => 'KBaseGenomes.Genome', 'name' => $mg_genome, 'data' => $decoded2}]});

        my $mp_contigs = "kb|g.20403.c.0";
	open (CONTIG, "kb_g.20403.contigset.json");
        my $obj3 = <CONTIG>;
	chomp $obj3;
	close CONTIG;
	my $decoded = JSON::XS::decode_json($obj3);
        $ws_client->save_objects({'workspace' => get_ws_name(), 'objects' => [{'type' => 'KBaseGenomes.ContigSet', 'name' => $mp_contigs, 'data' => $decoded}]});

	my $mp_genome = "Mp";
	open (GENOME, "Mycoplasma_pneumoniae_M129.json");
        my $obj4 = <GENOME>;
	chomp $obj4;
	close GENOME;
	my $decoded2 = JSON::XS::decode_json($obj4);
	$decoded2->{"contigset_ref"} = get_ws_name()."/".$mp_contigs;
        $ws_client->save_objects({'workspace' => get_ws_name(), 'objects' => [{'type' => 'KBaseGenomes.Genome', 'name' => $mp_genome, 'data' => $decoded2}]});

	print STDERR "Getting ready ...\n";

    eval { 
	my $ret = $impl->build_pangenome({workspace=>get_ws_name(), output_id=>"pg.1", genome_refs=>[get_ws_name()."/".$mg_genome,get_ws_name()."/".$mp_genome]});
	use Data::Dumper;
	print &Dumper($ret);
    };
    if ($@) {
	print("Error while running build_pangenome: $@\n");
    }
    eval { 
	my $ret = $impl->compare_genomes({workspace=>get_ws_name(), output_id=>"gc.1", pangenome_ref=>get_ws_name()."/pg.1"});
	use Data::Dumper;
	print &Dumper($ret);
    };
    if ($@) {
	print("Error while running compare_genomes: $@\n");
    }
    done_testing(0);
};
my $err = undef;
if ($@) {
    $err = $@;
}
eval {
    if (defined($ws_name)) {
        $ws_client->delete_workspace({workspace => $ws_name});
        print("Test workspace was deleted\n");
    }
};
if (defined($err)) {
    if(ref($err) eq "Bio::KBase::Exceptions::KBaseException") {
        die("Error while running tests: " . $err->trace->as_string);
    } else {
        die $err;
    }
}

{
    package LocalCallContext;
    use strict;
    sub new {
        my($class,$token,$user) = @_;
        my $self = {
            token => $token,
            user_id => $user
        };
        return bless $self, $class;
    }
    sub user_id {
        my($self) = @_;
        return $self->{user_id};
    }
    sub token {
        my($self) = @_;
        return $self->{token};
    }
    sub provenance {
        my($self) = @_;
        return [{'service' => 'GenomeComparison', 'method' => 'please_never_use_it_in_production', 'method_params' => []}];
    }
    sub authenticated {
        return 1;
    }
    sub log_debug {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
    sub log_info {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
}
