package PHEDEX::Web::API::Auth;
use warnings;
use strict;

=pod

=head1 NAME

PHEDEX::Web::API::Auth - check or enforce authentication

=head1 SYNOPSIS

Return the users' authentication state.

=head2 output

Returns the following structure

  <auth>
     <role/>
     <role/>
     ...
     <node/>
     <node/>
     ...
  </auth>
   ...

=head3 options

 ability : (optional) if passed then the nodes (from TMDB) that the user is
           allowed to operate on is are also returned.

 require_cert : (optional) if passed then the call will die if the
                user is not authenticated by certificate

=head3 <auth> attributes

 state : the authentication state (cert|passwd|failed)
 dn    : the user's distinguished name
 ability : the ability that authorized nodes were requested for (see options)

=head3 <role> attributes

 name  : the name of the role
 group : the group (or site) associated with the role

=head3 <node> attributes

 name : the name of the node
 id   : the id of the node

=cut

sub invoke { return auth(@_); }
sub auth
{
  my ($core,%args) = @_;

  $core->{SECMOD}->reqAuthnCert() if $args{require_cert};  
  my $auth = $core->getAuth($args{ability});

  # make XML-able data structure from our data
  my $obj = { 'state' => $auth->{STATE},
	      'dn' => $auth->{DN},
	      'ability' => $args{ability}
	  };

  foreach my $role (keys %{$auth->{ROLES}}) {
      foreach my $group (@{$auth->{ROLES}->{$role}}) {
	  $obj->{role} ||= [];
	  push @{$obj->{role}}, { name => $role, group => $group }
      }
  }

  foreach my $node (keys %{$auth->{NODES}}) {
      $obj->{node} ||= [];
      push @{$obj->{node}}, { name => $node,
			      id => $auth->{NODES}->{$node} };
  }

  return { auth => $obj };
}

1;
