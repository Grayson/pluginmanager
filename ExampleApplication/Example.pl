# use Foundation;
use CamelBones qw(:All);

sub actionProperty {
	return "label-click";
}

sub actionEnable {
	my ($withValue, $forValue) = @_;
	return 1;
}

sub actionTitle {
	my ($withValue, $forValue) = @_;
	return "Perl example";
}

sub actionPerform {
	my ($withValue, $forValue) = @_;
	print $withValue->description();
}
