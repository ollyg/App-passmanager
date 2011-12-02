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
    );
    $self->win->{status}->add('status', 'Label', 
        -text => "Quit: Ctrl-q or hit Escape",
        -x => 2,
        -bg => 'blue',
        -fg => 'black',
        -reverse => 1,
    );

    $self->win->{browse} = $self->ui->add(
        'browse', 'Window', 
        -title => "Browser",
        $self->win_config,
    );

    my $pw = $self->win->{browse}->{'-bw'}; # XXX private?
    my $lbw = int($pw / 3);

    $self->win->{browse}->add('category','Listbox',
        -title      => 'Category',
        -width      => $lbw,
        -border     => 1,
        -vscrollbar => 1,
        -wraparound => 1,
        -onchange   => sub { $self->select_category },
    );

    $self->win->{browse}->add('service','Listbox',
        -title      => 'Service',
        -width      => $lbw,
        -x          => $lbw,
        -border     => 1,
        -vscrollbar => 1,
        -wraparound => 1,
        -onchange   => sub { $self->select_service },
    );
    $self->win->{browse}->getobj('service')
        ->set_routine('loose-focus', sub { $self->update_browser });

    $self->win->{browse}->add('entry','Listbox',
        -title      => 'Entry',
        -width      => $lbw,
        -x          => (2 * $lbw),
        -border     => 1,
        -vscrollbar => 1,
        -wraparound => 1,
        -onchange   => sub { $self->select_entry },
    );
    $self->win->{browse}->getobj('entry')
        ->set_routine('loose-focus', sub { $self->select_category });
}

1;
