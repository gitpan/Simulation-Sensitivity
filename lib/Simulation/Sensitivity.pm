package Simulation::Sensitivity;
use strict;
use vars qw ($VERSION);
$VERSION = "0.11";

# Required modules
use Carp;
use Params::Validate ':all';

# ISA
use base qw( Class::Accessor::Fast );

#--------------------------------------------------------------------------#
# main pod documentation #####
#--------------------------------------------------------------------------#

=head1 NAME

Simulation::Sensitivity - A general-purpose sensitivity analysis tool for 
user-supplied calculations and parameters

=head1 SYNOPSIS

 use Simulation::Sensitivity;
 $sim = Simulation::Sensitiviy->new(
    calculation => sub { my $p = shift; return $p->{alpha} + $p->{beta} }
    parameters  => { alpha => 1.1, beta => 0.2 },
    delta       => 0.1 );
 $result = $sim->run;
 print $sim->text_report($result);

=head1 DESCRIPTION

Simulation::Sensitivity is a general-purpose sensitivity analysis tool.
Given a user-written calculating function, a "base-case" of parameters,
and a requested input sensitivity delta, this module will carry out a
sensitivity analysis, capturing the output of the calculating function
while varying each parameter positively and negatively by the specified 
delta.  The module also produces a simple text report showing the
percentage impact of each parameter upon the output.

The user-written calculating function must follow a standard form, but 
may make any type of computations so long as the form is satisfied.  It
must take a single argument -- a hash reference of parameters for use 
in the calculation.  It must return a single, numerical result.

=head1 CONSTRUCTORS

=cut

#--------------------------------------------------------------------------#
# new()
#--------------------------------------------------------------------------#

=head2 C<new> 

 my $sim = Simulation::Sensitivity->new(
    calculation => sub { my $p = shift; return $p->{alpha} + $p->{beta} }
    parameters  => { alpha => 1.1, beta => 0.2 },
    delta       => 0.1 );

C<new> takes as its argument a hash with three required parameters. 
C<calculation> must be a reference to a subroutine and is used for 
calculation.  It must adhere to the usage guidelines above for such 
functions.  C<parameters> must be a reference to a hash that represents
the initial starting parameters for the calculation.  C<delta> is a
percentage that each parameter will be pertubed by during the analysis.  
Percentages should be expressed as a decimal (0.1 to indicate 10%).  

As a constructor, C<new> returns a Simulation::Sensitivity object.

=cut

{
    my $param_spec = {
        calculation => { type => CODEREF },
        parameters => { type => HASHREF },
        delta => { type => SCALAR }
    };

    __PACKAGE__->mk_accessors( keys %$param_spec );

    sub new {
        my $class = shift;
        my %params = validate( @_, $param_spec );
        my $self = bless ({%params}, $class);
        return $self;
    }

}

=head1 PROPERTIES

=head2 C<calculation>, C<parameters>, C<delta>

 $sim->calculation()->({alpha=1.0, beta=1.0});
 %p = %{$sim->parameters()};
 $new_delta = $sim->delta(.15);

The parameter values in a Simulation::Sensitivity object may be 
retreived or modified using get/set accessors.  With no argument, the 
accessor returns the value of the parameter.  With an argument, the
accessor sets the value to the new value and returns the new value.

=cut 


#--------------------------------------------------------------------------#
# base()
#--------------------------------------------------------------------------#

=head1 METHODS

=head2 C<base>

 $base_case = base();

This method returns the base-case result for the parameter values provided
in the constructor.
 
=cut

sub base {
	my ($self) = @_;
    return $self->calculation->( { %{$self->parameters }} );	
}

#--------------------------------------------------------------------------#
# run()
#--------------------------------------------------------------------------#

=head2 C<run>

 $results = run();

This method returns a hash reference containing the results of the
sensitivity analysis.  The keys of the hash are the same as the keys of the
parameters array.  The values of the hash are themselves a hash reference
with each key representing a particular case in string form (e.g. "+10%" or
"-10%") and the value equal to the result from the calculation.  A simple
example would be:

 {
     alpha => {
         "+25%" => 5.25,
         "-25%" => 4.75
     },
     beta => {
         "+25%" => 6,
         "-25%" => 4
     }
 }


=cut

sub run {
	my ($self) = @_;
    my $results;
    
    for my $key ( keys %{$self->parameters} ) {
        $results->{$key} = {};
        for my $mult ( 1, -1 ) {
            my $p = { %{$self->parameters} };
            $p->{$key} = (1 + $mult * $self->delta ) * 
                         $self->parameters->{$key};
            $results->{$key}->{$self->_case($mult)} = 
                $self->calculation->($p);
        }
    }
    return $results;
}

#--------------------------------------------------------------------------#
# _case ($mult, $result, $base) 
#
# private helper function to turn a +/-1 into a case label using the delta
#--------------------------------------------------------------------------#

sub _case {
    my ($self, $mult) = @_;
    return (($mult == 1) ? "+" : "-") . ($self->delta * 100) . "%";
}


#--------------------------------------------------------------------------#
# text_report()
#--------------------------------------------------------------------------#

=head2 C<text_report>

 $report = text_report( $results );

This method generates a text string containing a simple, multi-line report.
The only parameter is a hash reference containing a set of results produced
with C<run>.

=cut

sub text_report {
	my ($self, $results) = @_;
	my $base = $self->base;
    croak "Simulation base case is zero/undefined.  Cannot generate report." 
        unless $base;
    my $report = sprintf("%12s %9s %9s\n",
        "Parameter",
        $self->_case(1),
        $self->_case(-1)
    );
    $report .= sprintf( "-" x 36 . "\n");
    for my $param (keys %$results) {
        my $cases = $results->{$param};
        $report .= sprintf("%12s %+9.2f%% %+9.2f%%\n",
            $param, 
            ($cases->{$self->_case(1)}/$base -1 ) * 100, 
            ($cases->{$self->_case(-1)}/$base -1 ) * 100,
        );
    }
    return $report; 
}

1; #this line is important and will help the module return a true value
__END__

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted by email to C<bug-Simulation-Sensitivity@rt.cpan.org> or 
through the web interface at 
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Simulation-Sensitivity>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

David A Golden (DAGOLDEN)

dagolden@cpan.org

L<http://dagolden.com/>

=head1 COPYRIGHT

Copyright (c) 2006 by David A Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
