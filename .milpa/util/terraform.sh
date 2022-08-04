#!/usr/bin/env bash

function @tf.dc () {
  at_root "terraform/$1"
  shift
  dc="$1"
  shift
  [[ -d ".terraform" ]] || terraform init
  terraform workspace select "$dc" || @milpa.fail "could not select workspace"
  terraform apply "${@}" || @milpa.fail "Could not apply changes"
}

function @tf () {
  at_root "terraform/$1"

  shift
  [[ -d ".terraform" ]] || terraform init
  terraform apply "${@}" || @milpa.fail "Could not apply changes"
}

function @tf.vars_dc () {
  at_root "terraform/$1"
  shift
  dc="$1"
  shift
  [[ -d ".terraform" ]] || terraform init
  terraform workspace select "$dc" || @milpa.fail "could not select workspace"
  cat >terraform.tfvars.json
  terraform apply "${@}" || {
    rm terraform.tfvars.json
    @milpa.fail "Could not apply changes"
  }
  rm terraform.tfvars.json
}

function @tf.vars () {
  at_root "terraform/$1"
  shift
  [[ -d ".terraform" ]] || terraform init
  cat >terraform.tfvars.json
  terraform apply "${@}" || {
    rm terraform.tfvars.json
    @milpa.fail "Could not apply changes"
  }
  rm terraform.tfvars.json
}
