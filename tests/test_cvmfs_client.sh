#!/bin/bash

# Test the devenv-client container

# Make sure devenv-client triggers lanuch of cvmfs_nfs_server and test that CVMLFS is indeed loaded.
# This will alter the cvmfs_cache_nfs volume

setup_suite() {
  # Setup the test suite. This will create some volumes, etc. This may take awhile

  # Make the docker-compose.yaml file
  sed -e 's/<USER>/lyon/g' -e 's/<EXP>/gm2/g' -e 's/<NAME>/UT/g' ../compose/docker-compose.yml-TEMPLATE > docker-compose.yml

  # Make the external volumes
  echo 'Creating volumes'
  docker volume create --name=slash_root_UT
  docker volume create --name=cvmfs_cache_UT

  # Start the CVMFS container by running the client
  docker-compose run --rm devenv-client-UT ls /cvmfs
}

test_cvmfs_nofail() {
  assert_fail "docker-compose logs --tail='all' cvmfs_nfs_server | grep -v NFS | grep -i -q 'failed'" "!!!! CVMFS failed to mount"
}

test_running () {
  assert "docker-compose logs cvmfs_nfs_server | grep -q 'Running until killed'" "Container is running"
}

test_fermilab_cvmfs() {

  assert "docker-compose run -T --rm devenv-client-UT test -r /cvmfs/fermilab.opensciencegrid.org/products/common/etc/setups.sh" \
           "Cannot find /cvmfs/fermilab.opensciencegrid.org UPS setup script"

}

test_gm2_cvmfs() {
   assert "docker-compose run -T --rm devenv-client-UT test -r /cvmfs/gm2.opensciencegrid.org/prod/g-2/setup" \
           "Cannot find /cvmfs/gm2.opensciencegrid.org UPS setup script"
}

test_gm2_setup () {
  assert "docker-compose run -T --rm devenv-client-UT /bin/bash -l -c 'source /cvmfs/gm2.opensciencegrid.org/prod/g-2/setup'" \
          "Cannot setup gm2"
}
teardown_suite_fake() {
  echo "No tear-down"
}

teardown_suite() {
  # Tear down the test suite.
  docker-compose down

  echo "Removing volumes"
  docker volume rm slash_root_UT
  docker volume rm cvmfs_cache_UT

  rm docker-compose.yml
}
