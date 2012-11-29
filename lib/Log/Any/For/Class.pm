package Log::Any::For::Class;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

our $VERSION = '0.17'; # VERSION

use Data::Clone;
use Scalar::Util qw(blessed);
use Log::Any::For::Package qw(add_logging_to_package);

our %SPEC;

sub import {
    my $class = shift;

    for my $arg (@_) {
        if ($arg eq 'add_logging_to_class') {
            no strict 'refs';
            my @c = caller(0);
            *{"$c[0]::$arg"} = \&$arg;
        } else {
            add_logging_to_class(packages => [$arg]);
        }
    }
}

sub _default_precall_logger {
    my $args  = shift;
    my $margs = $args->{args};

    # exclude $self or package
    $margs->[0] = '$self' if blessed($margs->[0]);

    Log::Any::For::Package::_default_precall_logger($args);
}

sub _default_postcall_logger {
    my $args = shift;

    Log::Any::For::Package::_default_postcall_logger($args);
}

my $spec = clone $Log::Any::For::Package::SPEC{add_logging_to_package};
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

version 0.17

=head1 SYNOPSIS

 use Log::Any::For::Class qw(add_logging_to_class);
 add_logging_to_class(classes => [qw/My::Class My::SubClass/]);
 # now method calls to your classes are logged, by default at level 'trace'

=head1 DESCRIPTION

Most of the things that apply to L<Log::Any::For::Package> also applies to this
module, since this module uses add_logging_to_package() as its backend.

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

=item * B<logger_args> => I<any>

Pass arguments to logger.

This allows passing arguments to logger routine (see C<logger_args>).

=item * B<postcall_logger> => I<code>

Supply custom postcall logger.

Just like precallI<logger, but code will be called after subroutine/method is
called. Code will be given a hashref argument \%args containing these keys:
C<args> (arrayref, a shallow copy of the original @>), C<orig> (coderef, the
original subroutine/method), C<name> (string, the fully-qualified
subroutine/method name), C<result> (arrayref, the subroutine/method result),
C<logger_args> (arguments given when adding logging).

You can use this mechanism to customize logging.

=item * B<precall_logger> => I<code>

Supply custom precall logger.

Code will be called when logging subroutine/method call. Code will be given a
hashref argument \%args containing these keys: C<args> (arrayref, a shallow copy
of the original @_), C<orig> (coderef, the original subroutine/method), C<name>
(string, the fully-qualified subroutine/method name), C<logger_args> (arguments
given when adding logging).

You can use this mechanism to customize logging.

The default logger accepts these arguments (can be supplied via C<logger_args>):

=over

=item *

indent => INT (default: 0)


=back

Indent according to nesting level.

=over

=item *

max_depth => INT (default: -1)


=back

Only log to this nesting level. -1 means unlimited.

=back

Return value:

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

