# ----------------------------------------------------------------------------------------------------------------------
# rvm, ruby
# ----------------------------------------------------------------------------------------------------------------------
include rvm

$ruby       = 'ruby-2.0.0-p195'
$app        = 'bs'
$gemset     = "${ruby}@${app}"

rvm::system_user { 
    root: ; 
    void: ;
}

# system user for backward compatibility
rvm_system_ruby {
  $ruby: ensure => 'present', default_use => false;
}

rvm_gemset {
  $gemset:
      ensure      => present,
      require     => Rvm_system_ruby[$ruby]
}

# installing gems
rvm_gem {
  "${gemset}/bundler":
      ensure => '1.1.4', require => Rvm_gemset[$gemset];
}

