package App::PassManager::Role::CursesWin;
use Moose::Role;

with 'App::PassManager::Role::Content';

use Curses::UI;
use Scalar::Util 'weaken';

has _ui_options => (
    is => 'rw',
    isa => 'HashRef',
    auto_deref => 1,
    lazy_build => 1,
    accessor => 'ui_options',
);
sub _build__ui_options {    
    my $self = shift;
    weaken $self;
    return {
        -clear_on_exit => 1,
        -color_support => 1,
        -userdata => $self,
    };
}

has '_ui' => (
    is => 'ro',
    isa => 'Curses::UI',
    reader => 'ui',
    lazy_build => 1,
);

# must be lazy otherwise Curses::UI nobbles help output
sub _build__ui {
    my $self = shift;
    my $ui = Curses::UI->new( $self->ui_options );
    $ui->set_binding( sub { $self->cleanup }, "\cQ" );  # ctrl-q
    $ui->set_binding( sub { $self->cleanup }, "\x1b" ); # escape
    return $ui;
}

has '_windows' => (
    is => 'ro',
    isa => 'HashRef',
    reader => 'win',
    default => sub { {} },
);

has '_win_config' => (
    is => 'ro',
    isa => 'HashRef',
    reader => 'win_config',
    auto_deref => 1,
    lazy_build => 1,
);

sub _build__win_config {
    return {
        -border       => 1, 
        -titlereverse => 0, 
        -padbottom    => 1,
        -ipad         => 1,
    }
}

sub new_base_win {
    my $self = shift;

    $self->win->{status} = $self->ui->add(
        'statuswin', 'Window', 
        -border => 0, 
        -y      => -1, 
        -height => 1,
        -width => -1,
    );
    $self->win->{status}->add('status', 'Label', 
        -text => "Quit: Ctrl-q or hit Escape",
        -x => 2,
        -width => -1,
        -fg => 'magenta',
    );

    $self->win->{browse} = $self->ui->add(
        'browse', 'Window', 
        -title => "Browser",
        $self->win_config,
    );

    my $pw = $self->win->{browse}->{'-bw'}; # XXX private?
    my $lbw = int($pw / 3);

    my $cl = $self->win->{browse}->add('category','Listbox',
        -title      => 'Category',
        -width      => $lbw,
        -border     => 1,
        -vscrollbar => 1,
        -wraparound => 1,
        -onchange   => sub { $self->service_list },
    );
    $cl->set_binding( sub { $self->delete(
        'Category', $self->data, $cl->get_active_value)
    }, 'd' );
    $cl->set_binding( sub { $self->add_category($cl->get_active_value) }, 'a' );

    my $sl = $self->win->{browse}->add('service','Listbox',
        -title      => 'Service',
        -width      => $lbw,
        -x          => $lbw,
        -border     => 1,
        -vscrollbar => 1,
        -wraparound => 1,
        -onchange   => sub { $self->entry_list },
    );
    $sl->set_routine('loose-focus', sub { $self->category_list });
    $sl->set_binding( sub { $self->delete(
        'Service', $self->data->{category}->{$cl->get}, $sl->get_active_value)
    }, 'd' );
    $sl->set_binding( sub { $self->add_service($cl->get, $sl->get_active_value) }, 'a' );

    my $el = $self->win->{browse}->add('entry','Listbox',
        -title      => 'Entry',
        -width      => $lbw,
        -x          => (2 * $lbw),
        -border     => 1,
        -vscrollbar => 1,
        -wraparound => 1,
        -onchange   => sub { $self->display_entry },
    );
    $el->set_routine('loose-focus', sub { $self->service_list });
    $el->set_binding( sub { $self->delete(
        'Entry', $self->data->{category}->{$cl->get}->{service}->{$sl->get}, $el->get_active_value)
    }, 'd' );
    $el->set_binding( sub { $self->edit_entry($cl->get, $sl->get, $el->get_active_value) }, 'e' );
    $el->set_binding( sub { $self->add_entry($cl->get, $sl->get, $el->get_active_value) }, 'a' );
}

1;
