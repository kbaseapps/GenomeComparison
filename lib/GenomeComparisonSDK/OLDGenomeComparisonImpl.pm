package GenomeComparison::GenomeComparisonImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

GenomeComparison

=head1 DESCRIPTION

A KBase module: GenomeComparison
This sample module contains one small method - filter_contigs.

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use Bio::KBase::workspace::Client;
use Config::IniFiles;
use Data::Dumper;

sub function_to_roles{
	my ($self,$function) = @_;
	my $array = [split(/\#/,$function)];
	$function = shift(@{$array});
	$function =~ s/\s+$//;
	my @roles = split(/\s*;\s+|\s+[\@\/]\s+/,$function);
	return \@roles;
}

sub simple_role_reaction_hash {
	my ($self,$template,$map,$wsClient) = @_;
	my $biochemistry;
	eval {
	    $biochemistry= $wsClient->get_objects([{ref=>$template->{biochemistry_ref}}])->[0]{data};
	};
	if ($@) {
	    die "Error loading biochemistry from workspace:\n".$@;
	}
	my $rxns = $template->{templateReactions};
	my $rolehash = {};
	for (my $i=0;$i<@{$rxns};$i++) {
	    my $rxn = $rxns->[$i];
	    my $cpx_refs = $rxn->{complex_refs};
	    foreach my $cpx_ref (@$cpx_refs) {
		my $cpx;
		foreach my $cpxH (@{$map->{complexes}}) {
		    if (index($cpx_ref, $cpxH->{id}) >= 0) {
			$cpx = $cpxH;
			last;
		    }
		}
		if (! defined $cpx) {
		    die("Couldn't find role for $cpx_ref\n");
		}
		my $roles = $cpx->{complexroles};
		for (my $k=0; $k < @{$roles}; $k++) {
		    my $role_ref = $roles->[$k]->{role_ref};
		    my $role;
		    foreach my $roleH (@{$map->{roles}}) {
			if (index($role_ref, $roleH->{id}) >= 0) {
			    $role = $roleH;
			    last;
			}
		    }
		    if (! defined $role) {
			die("Couldn't find role for $role_ref\n");
		    }
		    my $reaction;
		    foreach my $rxnH (@{$biochemistry->{reactions}}) {
			if (index($rxn->{reaction_ref}, $rxnH->{id}) >= 0) {
			    $reaction = $rxnH;
			    last;
			}
		    }
		    if (! defined $reaction) {
			die("Couldn't find reaction for $rxn->{reaction_ref}\n");
		    }
		    my $compartment;
		    foreach my $cptH (@{$biochemistry->{compartments}}) {
			if (index($rxn->{compartment_ref}, $cptH->{id}) >= 0) {
			    $compartment = $cptH;
			    last;
			}
		    }
		    if (! defined $compartment) {
			die("Couldn't find compartment for $rxn->{compartment_ref}\n");
		    }
		    $rolehash->{$role->{name}}->{$reaction->{id}}->{$compartment->{id}} = [$rxn->{direction},$self->createEquation($reaction, $biochemistry)];
		}
	    }
	}
	return $rolehash;
}

sub createEquation {
	my ($self,$rxn, $bio) = @_;
	my $rgt = $rxn->{reagents};
	my $rgtHash;
	for (my $i=0; $i < @{$rgt}; $i++) {
	    my $id = (split "/", $rgt->[$i]->{compound_ref})[-1];
	    if (!defined($rgtHash->{$id}->{(split "/", $rgt->[$i]->{compartment_ref})[-1]})) {
		$rgtHash->{$id}->{(split "/", $rgt->[$i]->{compartment_ref})[-1]} = 0;
	    }
	    $rgtHash->{$id}->{(split "/", $rgt->[$i]->{compartment_ref})[-1]} += $rgt->[$i]->{coefficient};
	}
	my @reactcode = ();
	my @productcode = ();
	my $sign = " <=> ";
	$sign = " => " if $rxn->{direction} eq ">";
	$sign = " <= " if $rxn->{direction} eq "<";

	my %FoundComps=();
	my $CompCount=0;

	my $sortedCpd = [sort(keys(%{$rgtHash}))];
	for (my $i=0; $i < @{$sortedCpd}; $i++) {

	    #Cpds sorted on original modelseed identifiers
	    #But representative strings collected here (if not 'id')
	    my $printId=$sortedCpd->[$i];

	    my $comps = [sort(keys(%{$rgtHash->{$sortedCpd->[$i]}}))];
	    for (my $j=0; $j < @{$comps}; $j++) {
		my $compartment = $comps->[$j];
		$compartment = "[".$compartment."]";

		if ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} < 0) {
		    my $coef = -1*$rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
		    my $reactcode = "(".$coef.") ".$printId.$compartment;
		    push(@reactcode,$reactcode);
		    
		} elsif ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} > 0) {
		    my $coef = $rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};

		    my $productcode .= "(".$coef.") ".$printId.$compartment;
		    push(@productcode, $productcode);
		} 
	    }
	}

	my $reaction_string = join(" + ",@reactcode).$sign.join(" + ",@productcode);

	return $reaction_string;
}

sub util_configure_ws_id {
	my ($self,$ref) = @_;
	my $array = [split(/\//,$ref)];
	my $ws = $array->[0];
	my $id = $array->[1];
	my $input = {};
 	if ($ws =~ m/^\d+$/) {
 		$input->{wsid} = $ws;
	} else {
		$input->{workspace} = $ws;
	}
	if ($id =~ m/^\d+$/) {
		$input->{objid} = $id;
	} else {
		$input->{name} = $id;
	}
	if (defined($array->[2])) {
		$input->{ver} = $array->[2];
	}
	return $input;
}

sub util_runexecutable {
	my ($self,$Command) = @_;
	my $OutputArray;
	push(@{$OutputArray},`$Command`);
	return $OutputArray;
}

sub util_from_json {
	my ($self,$data) = @_;
    if (!defined($data)) {
    	die "Data undefined!";
    }
    return decode_json $data;
}

sub util_get_genome {
	my ($self,$wsClient,$token,$ref) = @_;
	my $info_array = $wsClient->get_object_info([$self->util_configure_ws_id($ref)],0);
	my $info = $info_array->[0];
	my $genome;
	if ($info->[2] =~ /GenomeAnnotation/) {
		my $output = $self->util_runexecutable($self->{"Data_API_script_directory"}.'get_genome.py "'.$self->{'workspace-url'}.'" "'.$self->{'shock-url'}.'" "'.$self->{"handle-service-url"}.'" "'.$token.'" "'.$info->[6]."/".$info->[0]."/".$info->[4].'" "'.$info->[1].'" 1');
		my $last = pop(@{$output});
		if ($last !~ m/SUCCESS/) {
			die "Genome failed to load!";
		}
		$genome = $self->util_from_json(pop(@{$output}));
		delete $genome->{contigobj};
	} else {
		$genome=$wsClient->get_objects([$self->util_configure_ws_id($ref)])->[0]{data};
	}
	$genome->{_reference} = $info->[6]."/".$info->[0]."/".$info->[4];
	return $genome;
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);
    $self->{'kbase-endpoint'} = $cfg->val('GenomeComparison','kbase-endpoint');
    $self->{'workspace-url'} = $cfg->val('GenomeComparison','workspace-url');
    $self->{'job-service-url'} = $cfg->val('GenomeComparison','job-service-url');
    $self->{'shock-url'} = $cfg->val('GenomeComparison','shock-url');
    $self->{'handle-service-url'} = $cfg->val('GenomeComparison','handle-service-url');
    $self->{'scratch'} = $cfg->val('GenomeComparison','scratch');
    $self->{'Data_API_script_directory'} = $cfg->val('GenomeComparison','Data_API_script_directory');
	if (!defined($self->{'workspace-url'})) {
		die "no workspace-url defined";
	}
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 build_pangenome

  $return = $obj->build_pangenome($input)

=over 4

=item Parameter and return types

=begin html

<pre>
$input is a GenomeComparison.BuildPangenomeParams
$return is a GenomeComparison.BuildPangenomeResult
BuildPangenomeParams is a reference to a hash where the following keys are defined:
	genome_refs has a value which is a reference to a list where each element is a string
	genomeset_ref has a value which is a string
	workspace has a value which is a string
	output_id has a value which is a string
BuildPangenomeResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string
	pg_ref has a value which is a string

</pre>

=end html

=begin text

$input is a GenomeComparison.BuildPangenomeParams
$return is a GenomeComparison.BuildPangenomeResult
BuildPangenomeParams is a reference to a hash where the following keys are defined:
	genome_refs has a value which is a reference to a list where each element is a string
	genomeset_ref has a value which is a string
	workspace has a value which is a string
	output_id has a value which is a string
BuildPangenomeResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string
	pg_ref has a value which is a string


=end text



=item Description



=back

=cut

sub build_pangenome
{
    my $self = shift;
    my($input) = @_;

    my @_bad_arguments;
    (ref($input) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to build_pangenome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_pangenome');
    }

    my $ctx = $GenomeComparison::GenomeComparisonServer::CallContext;
    my($return);
    #BEGIN build_pangenome
    my $token=$ctx->token;
    my $wsClient=Bio::KBase::workspace::Client->new($self->{'workspace-url'},token=>$token);
    my $provenance = [{}];
    $provenance = $ctx->provenance if defined $ctx->provenance;

    if (!exists $input->{'output_id'}) {
        die "Parameter output_id is not set in input arguments";
    }
    my $id = $input->{'output_id'};
    if (!exists $input->{'workspace'}) {
        die "Parameter workspace is not set in input arguments";
    }
    my $workspace_name=$input->{'workspace'};

    my %genomeH;
    if (defined $input->{genomeset_ref}) {
	eval {
	    my $genomeset=$wsClient->get_objects([{ref=>$input->{genomeset_ref}}])->[0]{data};
	    push @{$provenance->[0]->{'input_ws_objects'}}, $input->{genomeset_ref};
	    map { $genomeH{$_->{ref}} = 1 } values %{$genomeset->{elements}};
	};
    }
    if ($@) {
	die "Error loading genomeset from workspace:\n".$@;
    }
    if (defined $input->{genome_refs}) {
	eval {
	    my @refs;
	    foreach my $ref (@{$input->{genome_refs}}) {
		next if $ref eq ""; # widget does this if 1st genome input is left blank
		push @refs, {ref=>$ref};
	    }
	    if (@refs > 0) {
		my $genomeset_full=$wsClient->get_object_info_new({objects=>\@refs, includeMetadata=>1});
		map { $genomeH{ $_->[6]."/".$_->[0]."/".$_->[4] } = 1 } @$genomeset_full;
	    }
	};
    }
    if ($@) {
	die "Error loading genomes from workspace:\n".$@;
    }

    my @genomes = keys %genomeH;

    my $orthlist = [];
    my $okdb;
    my $pangenome = {
    	id => $id,
		type => "kmer",
		genome_refs => [],
		orthologs => [],
    };
    my $proteins = {};

    print STDERR "Processing ", scalar @genomes, " genomes\n";
    my $i = 0;
    foreach my $currgenome_name (@genomes) {
	my $currgenome_ref;
    	my $gkdb = {};
    	my $genepairs;
    	my $bestorthos = [];
	my $currgenome = undef;
	eval {
	    print STDERR "Getting object from workspace with ref $currgenome_ref\n";
	    $currgenome = $self->util_get_genome($wsClient,$token,$currgenome_name);
	    $currgenome_ref = $currgenome->{_reference};
	    push @{$provenance->[0]->{'input_ws_objects'}}, $currgenome_name;
	};
	if ($@) {
	    die "Error loading genome from workspace:\n".$@;
	}
	
    	push(@{$pangenome->{genome_refs}},$currgenome_ref);
    	if ($i == 1) {
    		my $array = [split(/\s/,$currgenome->{scientific_name})];
    		$pangenome->{name} = $array->[0]." pangenome";
    	}
    	my $ftrs = $currgenome->{features};
    	for (my $j=0; $j < @{$ftrs}; $j++) {
    		my $feature = $ftrs->[$j];
    		if (defined($feature->{protein_translation})) {
    			$proteins->{$feature->{id}} = $feature->{protein_translation};
    			my $matchortho;
    			my $bestortho;
    			my $bestscore = 0;
    			my $seq = $feature->{protein_translation};
    			for (my $k=	0; $k < (length($seq)-8); $k++) {
    				my $kmer = substr($seq,$k,8);
    				if ($i > 0) {
	    				if (defined($okdb->{$kmer})) {
	    					if (!defined($matchortho->{$okdb->{$kmer}})) {
	    						$matchortho->{$okdb->{$kmer}} = 0;
	    					}
	    					$matchortho->{$okdb->{$kmer}}++;
	    					if ($matchortho->{$okdb->{$kmer}} > $bestscore) {
	    						$bestscore = $matchortho->{$okdb->{$kmer}};
	    						$bestortho = $okdb->{$kmer};
	    					}
	    				}
    				}
    				if (defined($gkdb->{$kmer}) && !defined($gkdb->{$kmer}->{-1})) {
    					if (keys(%{$gkdb->{$kmer}}) >= 5) {
    						my $keylist = [keys(%{$gkdb->{$kmer}})];
    						for (my $m=0; $m < 4; $m++) {
    							for (my $n=($m+1); $n < 5; $n++) {
    								$genepairs->{$keylist->[$m]}->{$keylist->[$n]}--;
    								$genepairs->{$keylist->[$n]}->{$keylist->[$m]}--;
    							}
    						}
    						$gkdb->{$kmer} = {-1 => 0};
    					} else {
    						foreach my $key (keys(%{$gkdb->{$kmer}})) {
    							if ($key ne $j) {
    								if (!defined($genepairs->{$key}->{$j})) {
    									$genepairs->{$key}->{$j} = 0;
    									$genepairs->{$j}->{$key} = 0;
    								}
    								$genepairs->{$key}->{$j}++;
    								$genepairs->{$j}->{$key}++;
    							}
    						}
    						$gkdb->{$kmer}->{$j} = 1;
    					}
    				} else {
    					$gkdb->{$kmer}->{$j} = 1;
    				}
    			}
    			if ($bestscore < 10) {
    				$bestorthos->[$j] = -1;
    			} else {
    				$bestorthos->[$j] = $bestortho;
    				push(@{$pangenome->{orthologs}->[$bestortho]->{orthologs}},[$ftrs->[$j]->{id},0,$currgenome_ref]);
    			}
    		}
    	};
    	foreach my $kmer (keys(%{$gkdb})) {
    		if (!defined($gkdb->{$kmer}->{-1})) {
	    		my $keep = 1;
	    		if (keys(%{$gkdb->{$kmer}}) > 1) {
	    			my $keylist = [keys(%{$gkdb->{$kmer}})];
	    			for (my $m=0; $m < (@{$keylist}-1); $m++) {
	    				for (my $n=($m+1); $n < @{$keylist}; $n++) {
	    					if ($genepairs->{$keylist->[$m]}->{$keylist->[$n]} < 10 && $bestorthos->[$keylist->[$m]] == $bestorthos->[$keylist->[$n]]) {
	    						$keep = 0;
	    						$m = 1000;
	    						last;
	    					};
	    				}
	    			}
	    		}
	    		if ($keep == 1) {
	    			foreach my $gene (keys(%{$gkdb->{$kmer}})) {
	    				if ($bestorthos->[$gene] == -1) {
	    					$bestorthos->[$gene] = @{$pangenome->{orthologs}};
	    					my $list = [[$ftrs->[$gene]->{id},0,$currgenome_ref]];
	    					foreach my $partner (keys(%{$genepairs->{$gene}})) {
	    						if ($genepairs->{$gene}->{$partner} >= 10 && $bestorthos->[$partner] == -1) {
	    							$bestorthos->[$partner] = @{$pangenome->{orthologs}};
	    							push(@{$list},[$ftrs->[$partner]->{id},0,$currgenome_ref]);
	    						}
	    					}
	    					my $seq = $ftrs->[$gene]->{protein_translation};
	    					my $index = @{$pangenome->{orthologs}};
	    					my $neworthofam = {
						    	id => $ftrs->[$gene]->{id},
						    	type => $ftrs->[$gene]->{type},
						    	function => $ftrs->[$gene]->{function},
								protein_translation => $ftrs->[$gene]->{protein_translation},
								orthologs => $list
						    };
						    if (!defined($neworthofam->{function})) {
						    	$neworthofam->{function} = "unknown";
						    }
	    					push(@{$pangenome->{orthologs}},$neworthofam);
	    				}
	    				$okdb->{$kmer} = $bestorthos->[$gene];
	    			}
	    		}
    		}
    	}
	$i++;
    }
    print STDERR "Final score computing!\n";
    foreach my $kmer (keys(%{$okdb})) {
    	my $index = $okdb->{$kmer};
    	my $list = $pangenome->{orthologs}->[$index]->{orthologs};
    	my $hits = [];
    	for (my $i=0; $i < @{$list}; $i++) {
    		if (index($proteins->{$list->[$i]->[0]},$kmer) >= 0) {
    			push(@{$hits},$i);
    		}
    	}
    	my $numhits = @{$hits};
    	my $numorthos = @{$list};
    	if ((2*$numhits) >= $numorthos) {
    		foreach my $item (@{$hits}) {
    			$list->[$item]->[1]++;
    		}
    	}
    }

    my $pg_metadata = $wsClient->save_objects({
	'workspace' => $workspace_name,
	'objects' => [{
	    type => 'KBaseGenomes.Pangenome',
	    name => $id,
	    data => $pangenome,
	    'provenance' => $provenance
		      }]});

    my $report = "Pangenome saved to $workspace_name/$id\n";
    my $reportObj = { "objects_created"=>[{'ref'=>"$workspace_name/$id", "description"=>"Pangenome"}],
		      "text_message"=>$report };
    my $reportName = "pangenome_report_${id}";

    my $metadata = $wsClient->save_objects({
	'id' => $pg_metadata->[0]->[6],
	'objects' => [{
	    type => 'KBaseReport.Report',
	    data => $reportObj,
	    name => $reportName,
	    'meta' => {},
	    'hidden' => 1,
	    'provenance' => $provenance
		      }]});

    $return = { 'report_name'=>$reportName, 'report_ref', $metadata->[0]->[6]."/".$metadata->[0]->[0]."/".$metadata->[0]->[4], 'pg_ref' => $workspace_name."/".$id};
    #END build_pangenome
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to build_pangenome:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_pangenome');
    }
    return($return);
}




=head2 compare_genomes

  $return = $obj->compare_genomes($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a GenomeComparison.CompareGenomesParams
$return is a GenomeComparison.CompareGenomesResult
CompareGenomesParams is a reference to a hash where the following keys are defined:
	pangenome_ref has a value which is a string
	protcomp_ref has a value which is a string
	output_id has a value which is a string
	workspace has a value which is a string
CompareGenomesResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string
	cg_ref has a value which is a string

</pre>

=end html

=begin text

$params is a GenomeComparison.CompareGenomesParams
$return is a GenomeComparison.CompareGenomesResult
CompareGenomesParams is a reference to a hash where the following keys are defined:
	pangenome_ref has a value which is a string
	protcomp_ref has a value which is a string
	output_id has a value which is a string
	workspace has a value which is a string
CompareGenomesResult is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string
	cg_ref has a value which is a string


=end text



=item Description

Compares the specified genomes and computes unique features and core features

=back

=cut

sub compare_genomes
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to compare_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_genomes');
    }

    my $ctx = $GenomeComparison::GenomeComparisonServer::CallContext;
    my($return);
    #BEGIN compare_genomes
    my $token=$ctx->token;
    my $wsClient=Bio::KBase::workspace::Client->new($self->{'workspace-url'},token=>$token);
    my $provenance = [{}];
    $provenance = $ctx->provenance if defined $ctx->provenance;
    
    my $orthos;
    my $members = {};
    my $genome_refs;
    my $gc = {
	genomes => [],
	families => [],
	functions => [],
	core_functions => 0,
	core_families => 0
    };

    if (!exists $params->{'output_id'}) {
        die "Parameter output_id is not set in input arguments";
    }
    my $id = $params->{'output_id'};
    if (!exists $params->{'workspace'}) {
        die "Parameter workspace is not set in input arguments";
    }
    my $workspace_name=$params->{'workspace'};

    if (defined($params->{pangenome_ref})) {
	my $pg;
	eval {
	    $pg=$wsClient->get_objects([{ref=>$params->{pangenome_ref}}])->[0]{data};
	    push @{$provenance->[0]->{'input_ws_objects'}}, $params->{pangenome_ref};
	};
	if ($@) {
	    die "Error loading pangenome from workspace:\n".$@;
	}
	$gc->{pangenome_ref} = $params->{pangenome_ref};
	$genome_refs = $pg->{genome_refs};
	my $refhash;
	for (my $i=0; $i < @{$genome_refs}; $i++) {
	    if (!defined($refhash->{$genome_refs->[$i]})) {
		$refhash->{$genome_refs->[$i]} = 1;
	    }
	}
	my $orthofam = $pg->{orthologs};
	for (my $i=0; $i < @{$orthofam}; $i++) {
	    for (my $j=0; $j < @{$orthofam->[$i]->{orthologs}}; $j++) {
		$orthos->{$orthofam->[$i]->{id}}->{$orthofam->[$i]->{orthologs}->[$j]->[2]}->{$orthofam->[$i]->{orthologs}->[$j]->[0]} = $orthofam->[$i]->{orthologs}->[$j]->[1];
		$members->{$orthofam->[$i]->{orthologs}->[$j]->[2]}->{$orthofam->[$i]->{orthologs}->[$j]->[0]} = $orthofam->[$i]->{id};
	    }
	}
    } elsif (defined($params->{protcomp_ref})) {
	my $pc;
	eval {
	    $pc=$wsClient->get_objects([{ref=>$params->{protcomp_ref}}])->[0]{data};
	    push @{$provenance->[0]->{'input_ws_objects'}}, $params->{protcomp_ref};
	};
	if ($@) {
	    die "Error loading protcomp from workspace:\n".$@;
	}
	$gc->{protcomp_ref} = $params->{protcomp_ref};
	$genome_refs = [$pc->{genome1ref},$pc->{genome2ref}];
	my $plist = $pc->{proteome1names};
	my $oplist = $pc->{proteome2names};
	my $d = $pc->{data1};
	for (my $i=0; $i < @{$plist}; $i++) {
	    my $family;
	    my $sorthos;
	    for (my $j=0; $j < @{$d->[$i]}; $j++) {
		if ($d->[$i]->[$j]->[2] >= 90) {
		    my $gene = $oplist->[$d->[$i]->[$j]->[0]];
		    $sorthos->{$gene} = $d->[$i]->[$j]->[1];
		    if (defined($members->{$genome_refs->[1]}->{$gene})) {
			$family = $members->{$genome_refs->[1]}->{$gene};
		    }
		}
	    }
	    if (!defined($family)) {
		$family = $plist->[$i];	
	    }
	    $orthos->{$family}->{$genome_refs->[0]}->{$plist->[$i]} = 100;
	    $members->{$genome_refs->[0]}->{$plist->[$i]} = $family;
	    foreach my $gene (keys(%{$sorthos})) {
		$members->{$genome_refs->[1]}->{$gene} = $family;
		$orthos->{$family}->{$genome_refs->[1]}->{$gene} = $sorthos->{$gene};
	    }
	}
	$d = $pc->{data2};
	for (my $i=0; $i < @{$oplist}; $i++) {
	    if (!defined($members->{$genome_refs->[1]}->{$oplist->[$i]})) {
		my $family;
		my $sorthos;
		for (my $j=0; $j < @{$d->[$i]}; $j++) {
		    if ($d->[$i]->[$j]->[2] >= 90) {
			my $gene = $plist->[$d->[$i]->[$j]->[0]];
			$sorthos->{$gene} = $d->[$i]->[$j]->[1];
			if (defined($members->{$genome_refs->[0]}->{$gene})) {
			    $family = $members->{$genome_refs->[0]}->{$gene};
			}
		    }
		}
		if (!defined($family)) {
		    $family = $oplist->[$i];	
		}
		$orthos->{$family}->{$genome_refs->[1]}->{$oplist->[$i]} = 100;
		$members->{$genome_refs->[1]}->{$oplist->[$i]} = $family;
		foreach my $gene (keys(%{$sorthos})) {
		    $members->{$genome_refs->[0]}->{$gene} = $family;
		    $orthos->{$family}->{$genome_refs->[0]}->{$gene} = $sorthos->{$gene};
		}
	    }
	}
    } else {
	die("Must provide either a pangenome or proteome comparison as input!");
    }

    $gc->{id} = $params->{workspace}."/".$params->{output_id};
    $gc->{name} = $params->{output_id};
    #Retrieving subsystem data from mapping
    my $template;
    eval {
	$template=$wsClient->get_objects([{ref=>"KBaseTemplateModels/GramNegModelTemplate"}])->[0]{data};
    };
    if ($@) {
	die "Error loading template from workspace:\n".$@;
    }
    my $map;
    eval {
	$map=$wsClient->get_objects([{ref=>$template->{mapping_ref}}])->[0]{data};
    };
    if ($@) {
	die "Error loading map from workspace:\n".$@;
    }
    my $SubsysRoles = {};
    my $GenomeHash = {};
    my $FunctionHash = {};
    my $rolesets = $map->{subsystems};
    for (my $i=0; $i < @{$rolesets}; $i++) {
	my $roleset = $rolesets->[$i];
	my $role_refs = $roleset->{role_refs};
	foreach my $role_ref (@{$role_refs}) {
	    my $role;
	    foreach my $roleH (@{$map->{roles}}) {
		if (index($role_ref, $roleH->{id}) >= 0) {
		    $role = $roleH;
		    last;
		}
	    }
	    if (! defined $role) {
		die("Couldn't find role for $role_ref\n");
	    }
	    $SubsysRoles->{$role->{name}} = $roleset;
	}
    }

    #Associating roles and reactions
    my $rolerxns = $self->simple_role_reaction_hash($template, $map,$wsClient);
    #Building genome comparison object
    my $famkeys = [keys(%{$orthos})];
    my $famind = {};
    for (my $i=0; $i < @{$famkeys}; $i++) {
	$famind->{$famkeys->[$i]} = $i;
    }
    my $funcind = {};
    my $funccount = 0;
    my $functions;
    my $totgenomes = @{$genome_refs};
    my $genomehash;
    my $families = {};
    my $i = 0;
    foreach my $genome_ref (@{$genome_refs}) {
	my $g;
	eval {
	    $g = $self->util_get_genome($wsClient,$token,$genome_ref);
	};
	if ($@) {
	    die "Error loading genome from workspace:\n".$@;
	}
	my $ftrs = $g->{features};
	my $genfam = {};
	my $genfun = {};
	for (my $j=0; $j < @{$ftrs}; $j++) {
	    my $ftr = $ftrs->[$j];
	    my $fam = $members->{$genome_ref}->{$ftr->{id}};
	    my $score = $orthos->{$fam}->{$genome_ref}->{$ftr->{id}};
	    my $roles = $self->function_to_roles($ftr->{function});
	    my $funind = [];
	    for (my $k=0; $k < @{$roles}; $k++) {
		if (!defined($functions->{$roles->[$k]})) {
		    $functions->{$roles->[$k]} = {
			core => 0,
			genome_features => {},
			id => $roles->[$k],
			reactions => [],
			subsystem => "none",
			primclass => "none",
			subclass => "none",
			number_genomes => 0,
			fraction_genomes => 0,
			fraction_consistent_families => 0,
			most_consistent_family => "none",
		    };
		    $funcind->{$roles->[$k]} = $funccount;
		    $funccount++;
		    if (defined($SubsysRoles->{$roles->[$k]})) {
			$functions->{$roles->[$k]}->{subsystem} = $SubsysRoles->{$roles->[$k]}->{name};
			$functions->{$roles->[$k]}->{primclass} = $SubsysRoles->{$roles->[$k]}->{class};
			$functions->{$roles->[$k]}->{subclass} = $SubsysRoles->{$roles->[$k]}->{subclass};
		    }
		    if (defined($rolerxns->{$roles->[$k]})) {
			foreach my $rxn (keys(%{$rolerxns->{$roles->[$k]}})) {
			    foreach my $comp (keys(%{$rolerxns->{$roles->[$k]}->{$rxn}})) {
				push(@{$functions->{$roles->[$k]}->{reactions}},[$rxn."_".$comp,$rolerxns->{$roles->[$k]}->{$rxn}->{$comp}->[1]]);
			    }
			}
		    }
		}
		push(@{$funind},$funcind->{$roles->[$k]});
		push(@{$functions->{$roles->[$k]}->{genome_features}->{$genome_ref}},[$ftr->{id},$famind->{$fam},$score]);
		$genfun->{$roles->[$k]} = 1;
	    }
	    if (!defined($families->{$fam})) {
		$families->{$fam} = {
		    core => 0,
		    genome_features => {},
		    id => $fam,
		    type => $ftr->{type},
		    protein_translation => "none",
		    number_genomes => 0,
		    fraction_genomes => 0,
		    fraction_consistent_annotations => 0,
		    most_consistent_role => "none",
		};
	    }
	    $genfam->{$fam} = 1;
	    push(@{$families->{$fam}->{genome_features}->{$genome_ref}},[$ftr->{id},$funind,$score]);
	}
	my $taxonomy = "Unknown";
	if (defined($g->{taxonomy})) {
	    $taxonomy = $g->{taxonomy};
	}
	my $numftrs = @{$ftrs};
	my $numfams = keys(%{$genfam});
	my $numfuns = keys(%{$genfun});
	$genomehash->{$genome_ref} = {
	    id => $genome_ref,
	    name => $g->{scientific_name},
	    taxonomy => $taxonomy,
	    genome_ref => $genome_ref,
	    genome_similarity => {},
	    features => $numftrs,
	    families => $numfams+0,
	    functions => $numfuns+0,
	};
	$gc->{genomes}->[$i] = $genomehash->{$genome_ref};
	$i++;
    }
    foreach my $function (keys(%{$funcind})) {
	foreach my $genone (keys(%{$functions->{$function}->{genome_features}})) {
	    foreach my $gentwo (keys(%{$functions->{$function}->{genome_features}})) {
		if ($genone ne $gentwo) {
		    if (!defined($genomehash->{$genone}->{genome_similarity}->{$gentwo})) {
			$genomehash->{$genone}->{genome_similarity}->{$gentwo} = [0,0];
		    }
		    $genomehash->{$genone}->{genome_similarity}->{$gentwo}->[1]++;
		}
	    }
	}
	$functions->{$function}->{number_genomes} = keys(%{$functions->{$function}->{genome_features}});
	$functions->{$function}->{fraction_genomes} = $functions->{$function}->{number_genomes}/$totgenomes;
	if ($functions->{$function}->{fraction_genomes} == 1) {
	    $functions->{$function}->{core} = 1;
	    $gc->{core_functions}++;
	}
	$gc->{functions}->[$funcind->{$function}] = $functions->{$function};
    }
    foreach my $fam (keys(%{$famind})) {
	foreach my $genone (keys(%{$families->{$fam}->{genome_features}})) {
	    foreach my $gentwo (keys(%{$families->{$fam}->{genome_features}})) {
		if ($genone ne $gentwo) {
		    if (!defined($genomehash->{$genone}->{genome_similarity}->{$gentwo})) {
			$genomehash->{$genone}->{genome_similarity}->{$gentwo} = [0,0];
		    }
		    $genomehash->{$genone}->{genome_similarity}->{$gentwo}->[0]++;
		}
	    }
	}
	$families->{$fam}->{number_genomes} = keys(%{$families->{$fam}->{genome_features}});
	$families->{$fam}->{fraction_genomes} = $families->{$fam}->{number_genomes}/$totgenomes;
	if ($families->{$fam}->{fraction_genomes} == 1) {
	    $families->{$fam}->{core} = 1;
	    $gc->{core_families}++;
	}
	$gc->{families}->[$famind->{$fam}] = $families->{$fam};
    }

    my $gc_metadata = $wsClient->save_objects({
	'workspace' => $workspace_name,
	'objects' => [{
	    type => 'KBaseGenomes.GenomeComparison',
	    name => $id,
	    data => $gc,
	    'provenance' => $provenance
		      }]});

    my $report = "GenomeComparison saved to $workspace_name/$id\n";
    my $reportObj = { "objects_created"=>[{'ref'=>"$workspace_name/$id", "description"=>"GenomeCompmarison"}],
		      "text_message"=>$report };
    my $reportName = "genomecomparison_report_${id}";

    my $metadata = $wsClient->save_objects({
	'id' => $gc_metadata->[0]->[6],
	'objects' => [{
	    type => 'KBaseReport.Report',
	    data => $reportObj,
	    name => $reportName,
	    'meta' => {},
	    'hidden' => 1,
	    'provenance' => $provenance
		      }]});

    $return = { 'report_name'=>$reportName, 'report_ref', $metadata->[0]->[6]."/".$metadata->[0]->[0]."/".$metadata->[0]->[4], 'cg_ref' => $workspace_name."/".$id};
    #END compare_genomes
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to compare_genomes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'compare_genomes');
    }
    return($return);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 BuildPangenomeParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
genome_refs has a value which is a reference to a list where each element is a string
genomeset_ref has a value which is a string
workspace has a value which is a string
output_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
genome_refs has a value which is a reference to a list where each element is a string
genomeset_ref has a value which is a string
workspace has a value which is a string
output_id has a value which is a string


=end text

=back



=head2 BuildPangenomeResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string
pg_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string
pg_ref has a value which is a string


=end text

=back



=head2 CompareGenomesParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
pangenome_ref has a value which is a string
protcomp_ref has a value which is a string
output_id has a value which is a string
workspace has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
pangenome_ref has a value which is a string
protcomp_ref has a value which is a string
output_id has a value which is a string
workspace has a value which is a string


=end text

=back



=head2 CompareGenomesResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string
cg_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string
cg_ref has a value which is a string


=end text

=back



=cut

1;
