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

sub update_browser {
    my $self = shift;
    # clear service and entry lists
    $self->win->{browse}->getobj('service')->values([]);
    $self->win->{browse}->getobj('entry')->values([]);

    # populate category list and set focus
    my $category = $self->win->{browse}->getobj('category');
    $category->values([keys %{$self->data->{category} || {}}]);
    $category->focus;
}

sub select_category {
    my $self = shift;
    # grab selected category
    $self->category($self->win->{browse}->getobj('category')->get);
    # clear entry list (for backtrack from entry)
    $self->win->{browse}->getobj('entry')->values([]);

    # populate service list and set focus
    my $service = $self->win->{browse}->getobj('service');
    $service->values([keys %{
        $self->data->{category}->{$self->category}->{service} || {}
    }]);
    $service->focus;
}

sub select_service {
    my $self = shift;
    # grab selected service
    $self->service($self->win->{browse}->getobj('service')->get);

    # populate entry list and set focus
    my $entry = $self->win->{browse}->getobj('entry');
    $entry->values([keys %{
        $self->data->{category}->{$self->category}
            ->{service}->{$self->service}->{entry} || {}
    }]);
    $entry->focus;
}

sub select_entry {
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

1;
