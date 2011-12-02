package App::PassManager::Command::open;
use Moose;

extends 'MooseX::App::Cmd::Command';
with qw/
    App::PassManager::CommandRole::Help
    App::PassManager::Role::Files
    App::PassManager::Role::Git
    App::PassManager::Role::CursesWin
    App::PassManager::Role::InitDialogs
/;

sub abstract {
    return "browse and edit the password repository";
}

sub description {
    return <<ENDDESC;
This command will ask for your personal password then open the password
repository for browsing and editing.
ENDDESC
}

sub execute {
    my ($self, $opt, $args) = @_;

    $self->init_git;

    # no stderr once we fire up Curses::UI
    open STDERR, '>/dev/null';

    $self->new_base_win;
    $self->get_user_win;

    $self->win->{get_user}->focus;
    $self->ui->mainloop;
}

1;
