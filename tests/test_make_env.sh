#!/bin/bash

# Test make_env.sh

setup_suite() {

# Let's make a contrived example by faking the `printenv` function
  fake printenv << EOF
A=a
USER=lyon
OLDPWD=/Users/lyon/Development/gm2/laserCalibConDB/srcs
PATH=/my/path
LANG=en_US.UTF-8
N=n
PWD=/Users/lyon/Development/gm2/laserCalibConDB/srcs/devenv/helpers
_=234
_OK=ok
TERM=xterm-256color
HOSTNAME=foo
Z=z
EOF

  ../helpers/make_env.sh > out.env
}

test_A() {
  assert "grep A=a out.env"
}

test_N() {
  assert "grep N=n out.env"
}

test_Z() {
  assert "grep Z=z out.env"
}

test_underscore_OK() {
  assert "grep ^_OK= out.env"
}

test_no_HOME() {
  assert_fail "grep ^HOME= out.env"
}

test_no_HOSTNAME() {
  assert_fail "grep ^HOSTNAME= out.env"
}

test_no_LANG() {
  assert_fail "grep ^LANG= out.env"
}

test_no_LS_COLORS() {
  assert_fail "grep ^LS_COLORS= out.env"
}

test_no_OLDPWD() {
  assert_fail "grep ^OLDPWD= out.env"
}

test_no_PWD() {
  assert_fail "grep ^PWD= out.env"
}

test_no_underscore() {
  assert_fail "grep ^_= out.env"
}

test_no_USER() {
  assert_fail "grep ^USER= out.env"
}

test_no_TERM() {
  assert_fail "grep ^TERM= out.env"
}

teardown_suite() {
  rm -f out.env
}