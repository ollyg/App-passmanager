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

my $dummy = { '- no values -' => 1 };

sub category_list {
    my $self = shift;

    # clear service and entry lists
    $self->win->{browse}->getobj('service')->values([]);
    $self->win->{browse}->getobj('entry')->values([]);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-Q or Escape | Abandon Changes: Ctrl-R | Add: A | Delete: D");

    # populate category list and set focus
    my $category = $self->win->{browse}->getobj('category');
    $category->values([sort keys %{$self->data->{category} || $dummy}]);
    $category->focus;
}

sub service_show {
    my $self = shift;
    # grab selected category
    my $cat = $self->win->{browse}->getobj('category')->get_active_value;
    # seem to be called spruriously so need this check
    return if not $cat or $cat eq '- no values -';

    # populate service list and redraw
    my $service = $self->win->{browse}->getobj('service');
    $service->values([sort keys %{
        $self->data->{category}->{$cat}->{service} || $dummy
    }]);
    $service->draw;
}

sub service_list {
    my $self = shift;

    # grab selected category
    my $item = $self->win->{browse}->getobj('category')->get;
    if ($item eq '- no values -') {
        $self->win->{browse}->getobj('category')->focus;
        return;
    }
    $self->category($item);

    # clear entry list (for backtrack from entry)
    $self->win->{browse}->getobj('entry')->values([]);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-Q or Escape | Abandon Changes: Ctrl-R | Add: A | Delete: D");

    # populate service list and set focus
    my $service = $self->win->{browse}->getobj('service');
    $service->values([sort keys %{
        $self->data->{category}->{$self->category}->{service} || $dummy
    }]);
    $service->focus;
}

sub entry_show {
    my $self = shift;
    # grab selected category
    my $svc = $self->win->{browse}->getobj('service')->get_active_value;
    # seem to be called spruriously so need this check
    return if not $svc or $svc eq '- no values -';

    # populate entry list and redraw
    my $entry = $self->win->{browse}->getobj('entry');
    $entry->values([sort keys %{
        $self->data->{category}->{$self->category}->{service}->{$svc}->{entry}
            || $dummy
    }]);
    $entry->draw;
}

sub entry_list {
    my $self = shift;

    # grab selected service
    my $item = $self->win->{browse}->getobj('service')->get;
    if ($item eq '- no values -') {
        $self->win->{browse}->getobj('service')->focus;
        return;
    }
    $self->service($item);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-Q or Escape | Abandon Changes: Ctrl-R | Add: A | Edit: E | Delete: D");

    # populate entry list and set focus
    my $entry = $self->win->{browse}->getobj('entry');
    $entry->values([sort keys %{
        $self->data->{category}->{$self->category}
            ->{service}->{$self->service}->{entry} || $dummy
    }]);
    $entry->focus;
}

sub display_entry {
    my $self = shift;

    # grab selected entry
    my $item = $self->win->{browse}->getobj('entry')->get;
    if ($item eq '- no values -') {
        $self->win->{browse}->getobj('entry')->focus;
        return;
    }
    $self->entry($item);

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

sub edit {
    my ($self, $name, $loc, $key) = @_;
    my $type = lc $name;
    return unless $key and exists $loc->{$type}->{$key};
    my $newkey;

    if ($type eq 'entry') {
    }
    else {
        $newkey = $self->ui->question(
            -title   => "Edit",
            -question => "$name Name:",
            -answer => $key,
        );
        return unless $newkey;
    }

    $loc->{$type}->{$newkey} = $loc->{$type}->{$key};
    delete $loc->{$type}->{$key};
    my $list = "${type}_list";
    $self->$list;
}

sub add {
    my ($self, $name, $loc) = @_;
    my $type = lc $name;
    $loc->{$type} ||= {};
    my ($key, $val);

    if ($type eq 'entry') {
    }
    else {
        $key = $self->ui->question(
            -title   => "New",
            -question => "$name Name:",
        );
        return unless $key;
        $val = {};
    }

    $loc->{$type}->{$key} = $val;
    my $list = "${type}_list";
    $self->$list;
}

1;
