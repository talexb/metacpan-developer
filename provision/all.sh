#!/bin/bash

# The puppet master needs a 'search' line in order to resolve correctly
# but resolv.conf is unreliable because it gets populated by the host OS.
grep -qE '^search ' /etc/resolv.conf || \
  echo 'search metacpan.org' >> /etc/resolv.conf


# Vagrant shared directories get owned by the vagrant user
# but some programs need certain (usually sub-) dirs to be user-writable.
# Create tmp dirs and mount them on top of the share to work around this.
function change_shared_dir_owner () {
  local user="$1" dest="$2"
  local src="/tmp/v-share-mounts/$dest"

  mkdir -p "$dest" "$src"
  chown "$user" "$src"

  # Only proceed if not already mounted.
  mount | grep -qF " $dest " && return

  mount --bind "$src" "$dest"
}

# The web app writes to ./var/tmp
change_shared_dir_owner metacpan /home/metacpan/metacpan.org/var

# API test suite writes to multiple dirs.
change_shared_dir_owner metacpan:vagrant /home/metacpan/api.metacpan.org/t/var/tmp
change_shared_dir_owner metacpan:vagrant /home/metacpan/api.metacpan.org/var/tmp

# CPAN::Faker 0.008 requires source dir to be writable (not sure why).
# https://github.com/CPAN-API/cpan-api/issues/277
# https://github.com/rjbs/CPAN-Faker/issues/1
# In the meantime the test suite can be run as the vagrant user.
chmod -R g+w /home/metacpan/api.metacpan.org/{t/,}var/tmp


# Puppet needs to own it's ssl dir.
change_shared_dir_owner puppet:puppet /etc/puppet/ssl


# Run puppet to cleanup and check everything is running
/etc/puppet/run.sh