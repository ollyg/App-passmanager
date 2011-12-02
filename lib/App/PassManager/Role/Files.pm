package App::PassManager::Role::Files;

use Moose::Role;

# git/default_store/store
# git/default_store/users/foo

has 'home' => (
    is => 'rw',
    isa => 'Str',
    default => "$ENV{HOME}/.passmanager", # XXX win32 support?
    documentation => q{Location of PassManager's files (~/.passmanager)},
);

sub git_home { return $_[0]->home . '/git' }

has 'store' => (
    is => 'rw',
    isa => 'Str',
    default => 'default_store',
    documentation => q{Name of the Password Store ("default_store")},
);

sub store_home  { return $_[0]->git_home .'/'. $_[0]->store }
sub store_file  { return $_[0]->store_home .'/store' }
sub master_file { return $_[0]->store_home .'/master' }

has 'username' => (
    is => 'rw',
    isa => 'Str',
    default => $ENV{USER},
    documentation => q{Identity of the first user given access to the new }.
        q{Password Store (your username)},
);

sub user_home { return $_[0]->store_home .'/users' }
sub user_file { return $_[0]->user_home .'/'. $_[0]->username }

1;
