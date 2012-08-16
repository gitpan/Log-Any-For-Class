
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Add logging to class",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Log-Any-For-Class",
  "dist_version" => "0.13",
  "license" => "perl",
  "module_name" => "Log::Any::For::Class",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Clean::JSON" => 0,
    "Data::Clone" => 0,
    "Log::Any" => 0,
    "Rinci" => "v1.1.0",
    "Sub::Uplevel" => 0,
    "perl" => "5.010000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
