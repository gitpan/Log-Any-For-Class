package Log::Any::For::Class;

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

our $VERSION = '0.23'; # VERSION

use Data::Clone;
use Scalar::Util qw(blessed);
use Log::Any::For::Package qw(add_logging_to_package);

our %SPEC;

sub import {
    my $class = shift;

    my $hook;
    while (@_) {
        my $arg = shift;
        if ($arg eq '-hook') {
            $hook = shift;
        } elsif ($arg eq 'add_logging_to_class') {
            no strict 'refs';
            my @c = caller(0);
            *{"$c[0]::$arg"} = \&$arg;
        } else {
            add_logging_to_class(classes => [$arg], import_hook=>$hook);
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

    if (!$args{precall_logger}) {
        $args{precall_logger} = \&_default_precall_logger;
        $args{logger_args}{precall_wrapper_depth} = 3;
    }
    if (!$args{postcall_logger}) {
        $args{postcall_logger} = \&_default_postcall_logger;
        $args{logger_args}{postcall_wrapper_depth} = 3;
    }
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

=encoding UTF-8

=head1 NAME

Log::Any::For::Class - Add logging to class

=head1 VERSION

version 0.23

=head1 SYNOPSIS

 use Log::Any::For::Class qw(add_logging_to_class);
 add_logging_to_class(classes => [qw/My::Class My::SubClass/]);
 # now method calls to your classes are logged, by default at level 'trace'

=head1 DESCRIPTION

Most of the things that apply to L<Log::Any::For::Package> also applies to this
module, since this module uses add_logging_to_package() as its backend.

=head1 FUNCTIONS


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

=item * B<import_hook> => I<bool> (default: 0)

Whether to install import (@INC) hook instead.

If this setting is true, then instead of installing logging to all existing
packages, an @INC import hook will be installed instead so that subsequent
modules that are loaded and that match C<packages> will be logged. So to log all
subsequent loaded modules, you can set C<packages> to C<['.*']>.

=item * B<logger_args> => I<any>

Pass arguments to logger.

This allows passing arguments to logger routine.

=item * B<postcall_logger> => I<code>

Supply custom postcall logger.

Just like C<precall_logger>, but code will be called after subroutine/method is
called. Code will be given a hashref argument \%args containing these keys:
C<args> (arrayref, a shallow copy of the original @_), C<orig> (coderef, the
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

C<indent> => INT (default: 0)


=back

Indent according to nesting level.

=over

=item *

C<max_depth> => INT (default: -1)


=back

Only log to this nesting level. -1 means unlimited.

=over

=item *

C<log_sub_args> => BOOL (default: 1)


=back

Whether to display subroutine arguments when logging subroutine entry. The default can also
be supplied via environment C<LOG_SUB_ARGS>.

=over

=item *

C<log_sub_result> => BOOL (default: 1)


=back

Whether to display subroutine result when logging subroutine exit. The default
can also be set via environment C<LOG_SUB_RESULT>.

=back

Return value:

=head1 SEE ALSO

L<Log::Any::For::Package>

L<Log::Any::For::DBI>, an application of this module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-For-Class>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Log-Any-For-Class>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-For-Class>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
