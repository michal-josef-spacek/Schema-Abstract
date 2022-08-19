package Schema::Abstract;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use JSON::XS qw(decode_json);
use List::Util qw(max);
use Perl6::Slurp qw(slurp);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Version.
	$self->{'version'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Load JSON file with versions.
	$self->{'_versions_json_file'} = $self->_versions_json_file;
	my $versions_json = slurp($self->{'_versions_json_file'});
	$self->{'_versions'} = decode_json($versions_json);

	# Set version to last if isn't defined.
	if (! defined $self->{'version'}) {
		$self->{'version'} = $self->{'_versions'}->{'versions'}->[-1]->{'version'};
	}

	# Check version format.
    	if ($self->{'version'} !~ /^([0-9]+\.[0-9]+\.[0-9]+)$/) {
		err "Version isn't in proper format.",
			'Version', $self->{'version'},
		;
	};

	# Mapping between version and db schema version.
	$self->{'_schema_for'} = {
		map { $_->{'version'} => $_->{'schema'} } @{$self->{'_versions'}->{versions}},
	};

	# Check schema version.
	if (! exists $self->{'_schema_for'}->{$self->{'version'}}) {
		err "Schema version doesn't exist.",
			'Version', $self->{'version'},
		;
	}
    	$self->{'_schema_version'} = $self->{'_schema_for'}->{$self->{'version'}};
	if ($self->{'_schema_version'} !~ /^([0-9]+)\.([0-9]+)\.([0-9]+)$/) {
		err 'Schema version has bad format.',
			'Schema version', $self->{'_schema_version'},
		;
	}

	# Load schema.
	$self->{'_schema_module_name'} = $class.'::'."$1\_$2\_$3";
	eval 'require '.$self->{'_schema_module_name'};
	if ($EVAL_ERROR) {
		err 'Cannot load module.',
			'Module name', $self->{'_schema_module_name'},
		;
	}

	return $self;
}

sub list_versions {
	my $self = shift;

	return sort map { $_->{'version'} } @{$self->{'_versions'}->{'versions'}};
}

sub schema {
	my $self = shift;

	return $self->{'_schema_module_name'};
}

sub schema_version {
	my $self = shift;

	return $self->{'_schema_version'};
}

sub version {
	my $self = shift;

	return $self->{'version'};
}

sub _versions_json_file {
	my $self = shift;

	err "We need to implement distribution JSON file with Schema versions.";

	return;
}

1;

__END__
