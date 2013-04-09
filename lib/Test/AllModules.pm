package Test::AllModules;
use strict;
use warnings;
use Module::Pluggable::Object;
use Test::More ();

our $VERSION = '0.061';

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/all_ok/;

sub all_ok {
    my %param = @_;

    my $search_path = $param{search_path};
    my @checks;
    if (ref($param{check}) eq 'CODE') {
        push @checks, +{ test => $param{check}, name => '', };
    }
    else {
        for my $check ( $param{check}, @{ $param{checks} || [] } ) {
            my ($name) = keys %{$check || +{}};
            my $test   = $name ? $check->{$name} : undef;
            if (ref($test) eq 'CODE') {
                push @checks, +{ test => $test, name => "$name: ", };
            }
        }
    }

    unless ($search_path) {
        Test::More::plan skip_all => 'no search path';
        exit;
    }

    Test::More::plan('no_plan');
    my @exceptions = @{ $param{except} || [] };

    for my $class (
        grep { !_is_excluded( $_, @exceptions ) }
            _classes($search_path, \%param) ) {

        for my $check (@checks) {
            Test::More::ok(
                $check->{test}->($class),
                "$check->{name}$class",
            );
        }

    }
}

sub _classes {
    my ($search_path, $param) = @_;

    local @INC = @{ $param->{lib} || ['lib'] };
    my $finder = Module::Pluggable::Object->new(
        search_path => $search_path,
    );
    my @classes = ( $search_path, $finder->plugins );

    return $param->{shuffle} ? _shuffle(@classes) : sort(@classes);
}

# This '_shuffle' method copied
# from http://blog.nomadscafe.jp/archives/000246.html
sub _shuffle {
    map { $_[$_->[0]] } sort { $a->[1] <=> $b->[1] } map { [$_ , rand(1)] } 0..$#_;
}

# This '_any' method copied from List::MoreUtils.
sub _any (&@) { ## no critic
    my $f = shift;

    foreach ( @_ ) {
        return 1 if $f->();
    }
    return;
}

sub _is_excluded {
    my ( $module, @exceptions ) = @_;
    _any { $module eq $_ || $module =~ /$_/ } @exceptions;
}

1;

__END__

=head1 NAME

Test::AllModules - do some tests for modules in search path


=head1 SYNOPSIS

    # simplest
    use Test::AllModules;

    BEGIN {
        all_ok(
            search_path => 'MyApp',
            check => sub {
                my $class = shift;
                eval "use $class;1;";
            },
        );
    }

    # if you need the name of test
    use Test::AllModules;

    BEGIN {
        all_ok(
            search_path => 'MyApp',
            check => +{
                'use_ok' => sub {
                    my $class = shift;
                    eval "use $class;1;";
                },
            },
        );
    }

    # more tests, all options
    use Test::AllModules;

    BEGIN {
        all_ok(
            search_path => 'MyApp',
            checks => [
                +{
                    'use_ok' => sub {
                        my $class = shift;
                        eval "use $class;1;";
                    },
                },
            ],

            # `except` and `lib` are optional.
            except => [
                'MyApp::Role',
                qr/MyApp::Exclude::.*/,
            ],

            lib => [
                'lib',
                't/lib',
            ],

            shuffle => 1, # shuffle a use list
        );
    }


=head1 DESCRIPTION

Test::AllModules is do some tests for modules in search path.


=head1 EXPORTED FUNCTIONS

=head2 all_ok

do C<check(s)> code as ok() for every modules in search path.


=head1 REPOSITORY

Test::AllModules is hosted on github
<http://github.com/bayashi/Test-AllModules>


=head1 AUTHOR

dann

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::LoadAllModules>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
