use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new( 
    module_name     => 'Simulation::Sensitivity',
    dist_author         => 'David A Golden <dagolden@cpan.org>',
    license             => 'perl',
    create_readme       => 1,
    create_makefile_pl  => 'traditional',
    requires        => {
        Class::Accessor::Fast => 0,
        Params::Validate => 0,
        Test::More => 0.45, # thread-safe
    },
)->create_build_script;
