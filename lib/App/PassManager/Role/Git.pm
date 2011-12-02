package App::PassManager::Role::Git;
use Moose::Role;

use Git::Wrapper;
use XML::Simple;

has '_git' => (
    is => 'ro',
    isa => 'Git::Wrapper',
    reader => 'git',
    lazy_build => 1,
);

sub _build__git {
    my $self = shift;
    return Git::Wrapper->new($self->git_home);
}

sub init_git {
    my $self = shift;

    # silently skip if passmanager home already exists
    if (! -d $self->home) {
        mkdir($self->home)
            or die qq{$0: failed to create home directory: "$!"\n};
    }

    # silently skip if git repo already exists
    if (! -d $self->git_home) {
        mkdir($self->git_home)
            or die qq{$0: failed to create git directory: "$!"\n};
        $self->git->init;
    }

    die qq{$0: git repo is dirty, but I don't yet know how to fix that!\n}
        if $self->git->status->is_dirty;
}

sub cleanup {
    my $self = shift;

    if ($self->data) {
        $self->encrypt_file($self->store_file, $self->master,
            split m/\n+/, XML::Simple::XMLout($self->data));
    }

    if ($self->git->status->is_dirty) {
        $self->git->add($self->git_home);
        $self->git->commit({ all => 1, message => "Updated by ". $self->username });
    }

    #$self->ui->leave_curses;
    #use Data::Dumper;
    #print Dumper $self->data;

    exit(0);
}

1;
