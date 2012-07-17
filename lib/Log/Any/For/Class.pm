package Log::Any::For::Class;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

our $VERSION = '0.07'; # VERSION

use Data::Clone;
use Scalar::Util qw(blessed);
# doesn't currently work, Log::Log4perl not fooled
#use Sub::Uplevel;

our %SPEC;
require Exporter;
use Log::Any::For::Package qw(add_logging_to_package);
our @ISA = qw(Log::Any::For::Package Exporter);
our @EXPORT_OK = qw(add_logging_to_class);

sub _default_precall_logger {
    my $args  = shift;
    my $margs = $args->{args};

    #uplevel 2, $args->{orig}, @$margs;

    # exclude $self or package
    $margs->[0] = '$self' if blessed($margs->[0]);

    $log->tracef("---> %s(%s)", $args->{name}, $margs);
}

sub _default_postcall_logger {
    my $args = shift;
    #uplevel 2, $args->{orig}, @{$args->{args}};

    if (@{$args->{result}}) {
        $log->tracef("<--- %s() = %s", $args->{name}, $args->{result});
    } else {
        $log->tracef("<--- %s()", $args->{name});
    }
}

my $spec = $Log::Any::For::Package::SPEC{add_logging_to_package};
$spec->{summary} = 'Add logging to class';
$spec->{description} = <<'_';

Logging will be done using Log::Any.

Currently this function adds logging around method calls, e.g.:

    -> Class::method(...)
    <- Class::method() = RESULT
    ...

_
delete $spec->{args}{packages};
$spec->{args}{classes} = {
    summary => 'Classes to add logging to',
    schema => ['array*' => {of=>'str*'}],
    req => 1,
    pos => 0,
};
delete $spec->{args}{filter_subs};
$spec->{args}{filter_methods} = {
    summary => 'Filter methods to add logging to',
    schema => ['array*' => {of=>'str*'}],
    description => <<'_',

The default is to add logging to all non-private methods. Private methods are
those prefixed by `_`.

_
};
$SPEC{add_logging_to_class} = $spec;
sub add_logging_to_class {
    my %args = @_;

    my $classes = $args{classes} or die "Please specify 'classes'";
    $classes = [$classes] unless ref($classes) eq 'ARRAY';
    delete $args{classes};

    my $filter_methods = $args{filter_methods};
    delete $args{filter_methods};

    $args{precall_logger}  //= \&_default_precall_logger;
    $args{postcall_logger} //= \&_default_postcall_logger;

    add_logging_to_package(
        %args,
        packages => $classes,
        filter_subs => $filter_methods,
    );
}

1;
# ABSTRACT: Add logging to class


__END__
=pod

=head1 NAME

Log::Any::For::Class - Add logging to class

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 use Log::Any::For::Class qw(add_logging_to_class);
 add_logging_to_class(classes => [qw/My::Class My::SubClass/]);
 # now method calls to your classes are logged, by default at level 'trace'

=head1 CREDITS

Some code portion taken from L<Devel::TraceMethods>.

=head1 SEE ALSO

L<Log::Any::For::Package>

L<Log::Any::For::DBI>, an application of this module.

=head1 DESCRIPTION


This module has L<Rinci> metadata.

=head1 FUNCTIONS


None are exported by default, but they are exportable.

=head2 add_logging_to_class(%args) -> any

Add logging to class.

Logging will be done using Log::Any.

Currently this function adds logging around method calls, e.g.:

    -> Class::method(...)
    <- Class::method() = RESULT
    ...

Arguments ('*' denotes required arguments):

=over 4

=item * B<classes>* => I<array>

Classes to add logging to.

=item * B<filter_methods> => I<array>

Filter methods to add logging to.

The default is to add logging to all non-private methods. Private methods are
those prefixed by C<_>.

=item * B<postcall_logger> => I<code>

Supply custom postcall logger.

Just like precallI<logger, but code will be called after method is call. Code
will be given a hash argument %args containing these keys: C<args> (arrayref, the
original @>), C<orig> (coderef, the original method), C<name> (string, the
fully-qualified method name), C<result> (arrayref, the method result).

You can use this mechanism to customize logging.

=item * B<precall_logger> => I<code>

Supply custom precall logger.

Code will be called when logging method call. Code will be given a hash argument
%args containing these keys: C<args> (arrayref, the original @_), C<orig>
(coderef, the original method), C<name> (string, the fully-qualified method
name).

You can use this mechanism to customize logging.

=back

Return value:

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

