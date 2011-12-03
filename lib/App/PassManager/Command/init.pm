package App::PassManager::Command::init;
use Moose;

extends 'MooseX::App::Cmd::Command';
with qw/
    App::PassManager::CommandRole::Help
    App::PassManager::Role::Files
    App::PassManager::Role::Git
    App::PassManager::Role::Store
    App::PassManager::Role::GnuPG
    App::PassManager::Role::CursesWin
    App::PassManager::Role::InitDialogs
/;

sub abstract {
    return "initialize git repository and password files";
}

sub description {
    return <<ENDDESC;
This command will initalize a new git repository, create a password store,
and ask the user for its master password, and their own user's password.
ENDDESC
}

sub execute {
    my ($self, $opt, $args) = @_;

    $self->init_git;

    die qq{$0: git repo is dirty, but I don't yet know how to fix that!\n}
        if $self->git->status->is_dirty;

    $self->init_store;

    # no stderr once we fire up Curses::UI
    open STDERR, '>/dev/null';

    $self->new_base_win;

    $self->new_thing_win('user','master');
    $self->new_thing_win('master','browse');

    $self->win->{user}->focus;
    $self->ui->mainloop;
}

1;
