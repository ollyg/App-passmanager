package App::PassManager::CommandRole::Help;

use Moose::Role;

before 'validate_args' => sub {
    my ($self, $opt, $args) = @_;
    if ($self->help_flag) {
        print $self->usage->leader_text, "\n\n";
        print $self->description, "\n";
        print $self->usage->option_text;
        exit(1);
    }
};

1;
