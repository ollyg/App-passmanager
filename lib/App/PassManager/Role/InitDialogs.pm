package App::PassManager::Role::InitDialogs;
use Moose::Role;

with qw/
    App::PassManager::Role::GnuPG
    App::PassManager::Role::Store
/;

use Curses qw(KEY_ENTER);
use XML::Simple;

sub get_user_win {
    my $self = shift;

    $self->win->{get_user} = $self->ui->add(
        'get_user', 'Window', 
        -title => "User Password",
        $self->win_config,
    );
    $self->win->{get_user}->add(
        "get_user_question", 'Dialog::Question',
        -question => "Enter your password",
    );
    my $q = $self->win->{get_user}->getobj("get_user_question");
    $q->getobj('answer')->set_password_char('*');
    $q->getobj('answer')->set_binding(sub { $self->do_browse }, KEY_ENTER());
    $q->getobj('buttons')->set_routine('press-button', sub { $self->do_browse });
}

sub new_thing_win {
    my ($self, $thing) = @_;

    $self->win->{$thing} = $self->ui->add(
        $thing, 'Window', 
        -title => (ucfirst $thing) ." Password",
        $self->win_config,
    );
    $self->win->{$thing}->add(
        "${thing}question", 'Dialog::Question',
        -question => "Enter the $thing password",
    );
    my $q = $self->win->{$thing}->getobj("${thing}question");
    $q->getobj('answer')->set_password_char('*');
    $q->getobj('answer')->set_binding(sub { $self->new_thing($thing) }, KEY_ENTER());
    $q->getobj('buttons')->set_routine('press-button', sub { $self->new_thing($thing) });
}

sub new_thing {
    my ($self, $thing) = @_;
    my $q = $self->win->{$thing}->getobj("${thing}question");
    my $response = $q->getobj('buttons')->get;
    my $value = $q->getobj('answer')->get;

    $self->cleanup if not $response;

    if (not $value) {
        $self->ui->error('Empty password, try again!');
        my $clear = "clear_$thing";
        $self->$clear;
        $q->getobj('answer')->text('');
        $q->getobj('question')->text("Enter the $thing password");
        return;
    }

    my $next = {
        user => 'master',
        master => 'browse',
    };

    if ($self->$thing) {
        if ($self->$thing eq $value) {
            $self->ui->delete($thing); # XXX hack :-/
            $self->win->{ $next->{$thing} }->focus;
            my $next_init = "init_". $next->{$thing};
            $self->$next_init;
            return;
        }
        else {
            $self->ui->error('Passwords do not match, try again!');
            my $clear = "clear_$thing";
            $self->$clear;
            $q->getobj('answer')->text('');
            $q->getobj('question')->text("Enter the $thing password");
        }
    }
    else {
        $self->$thing($value);
        $q->getobj('answer')->text('');
        $q->getobj('question')->text("Enter $thing password again");
    }

    $self->win->{$thing}->focus;
}

sub init_master {
    my $self = shift;
    # nothing to do here
}

sub init_browse {
    my $self = shift;
    # encrypt new store with master password
    $self->encrypt_file($self->store_file, $self->master, '<opt></opt>');
    # encrypt master password with user password
    $self->encrypt_file($self->user_file, $self->user, $self->master);

    $self->data(XML::Simple::XMLin('<opt></opt>', ForceArray => 1));
    $self->show_categories;
}

sub do_browse {
    my $self = shift;
    my $q = $self->win->{get_user}->getobj("get_user_question");
    my $response = $q->getobj('buttons')->get;
    my $value = $q->getobj('answer')->get;

    $self->cleanup if not $response;

    if (not $value) {
        $self->ui->error('Empty password, try again!');
        $q->getobj('answer')->text('');
        return;
    }

    $self->user($value);
    my $master = scalar eval {
        $self->decrypt_file($self->user_file, $self->user) };

    if (not $master) {
        $self->ui->error('Incorrect password, try again!');
        $q->getobj('answer')->text('');
        return;
    }

    $self->master($master);
    $self->data(XML::Simple::XMLin(
        (join '', ($self->decrypt_file($self->store_file, $self->master))),
        ForceArray => 1,
    ));

    $self->ui->delete('get_user'); # XXX hack :-/
    $self->show_categories;
    $self->win->{browse}->focus;
}

1;
