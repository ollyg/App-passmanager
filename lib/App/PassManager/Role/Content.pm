package App::PassManager::Role::Content;
use Moose::Role;

has '_data' => (
    is => 'rw',
    isa => 'HashRef',
    accessor => 'data',
);

has '_category' => (
    is => 'rw',
    isa => 'Str',
    accessor => 'category',
);

has '_service' => (
    is => 'rw',
    isa => 'Str',
    accessor => 'service',
);

has '_entry' => (
    is => 'rw',
    isa => 'Str',
    accessor => 'entry',
);

sub category_list {
    my $self = shift;
    # clear service and entry lists
    $self->win->{browse}->getobj('service')->values([]);
    $self->win->{browse}->getobj('entry')->values([]);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-q or hit Escape  //  Add: a  //  Delete: d");

    # populate category list and set focus
    my $category = $self->win->{browse}->getobj('category');
    $category->values([keys %{$self->data->{category} || {}}]);
    $category->focus;
}

sub service_list {
    my $self = shift;
    # grab selected category
    $self->category($self->win->{browse}->getobj('category')->get);
    # clear entry list (for backtrack from entry)
    $self->win->{browse}->getobj('entry')->values([]);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-q or hit Escape  //  Add: a  //  Delete: d");

    # populate service list and set focus
    my $service = $self->win->{browse}->getobj('service');
    $service->values([keys %{
        $self->data->{category}->{$self->category}->{service} || {}
    }]);
    $service->focus;
}

sub entry_list {
    my $self = shift;
    # grab selected service
    $self->service($self->win->{browse}->getobj('service')->get);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-q or hit Escape  //  Add: a  //  Edit: e  //  Delete: d");

    # populate entry list and set focus
    my $entry = $self->win->{browse}->getobj('entry');
    $entry->values([keys %{
        $self->data->{category}->{$self->category}
            ->{service}->{$self->service}->{entry} || {}
    }]);
    $entry->focus;
}

sub display_entry {
    my $self = shift;
    # grab selected entry
    $self->entry($self->win->{browse}->getobj('entry')->get);

    # throw up a dialog box with the fields
    my $loc = $self->data->{category}->{$self->category}
            ->{service}->{$self->service}->{entry}
            ->{$self->entry};
    $self->ui->dialog(
        "Username:    ". ($loc->{username} || '') ."\n".
        "Password:    ". ($loc->{password} || '') ."\n".
        "Description: ". ($loc->{description} || '')
    );
}

sub delete {
    my ($self, $name, $loc, $key) = @_;
    my $type = lc $name;
    return unless $key and exists $loc->{$type}->{$key};

    my $yes = $self->ui->dialog(
        -message => qq{Really delete $name "$key"?},
        -buttons => ['yes', 'no'],
        -values  => [1, 0],
        -title   => 'Confirm',
    );

    if ($yes) {
        delete $loc->{$type}->{$key};
        my $list = "${type}_list";
        $self->$list;
    }
}

1;
