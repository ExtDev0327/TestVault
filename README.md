This repo is an virtual vault for testing which is simply implementing deposit/withdraw functions with whitelisted tokens

## Contracts

### Vault

Implement fundemental functions of the vault

### Errors

Define custom errors for the vault

## Repository Structure

```ml
contracts/
├── Vault — "vault where users can deposit or withdraw any kind of erc20 tokens which is whitelisted on this system"
└── libraries
    └── Errors — "contains pre-defined errors on this system"
```

## Installation

This repo uses the Foundry framework for testing.
To get started, clone the repo
```bash
git clone https://github.com/extdev0327/TestVault.git --recurse-submodules
```

## Testing

Run the Foundry test suite:

```bash
$ forge test
```
