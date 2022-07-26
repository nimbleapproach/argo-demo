#!/usr/bin/env bash

[[ -z "${MY_EMAIL}" ]] && export MY_EMAIL=$(git config --get user.email)

ssh-keygen -t ed25519 -C "$MY_EMAIL" -f myNewKeyPair -N

export MY_PUB_KEY=$(cat myNewKeyPair.pub)
export MY_PRIVATE_KEY=$(cat myNewKeyPair)
rm myNewKeyPair*

echo "========================================================"
echo "Add this public key to https://github.com/settings/keys"
echo "$MY_PUB_KEY"
open https://github.com/settings/keys


echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "Add this PRIVATE key to your argo repo:"
echo "$MY_PRIVATE_KEY"