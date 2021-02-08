# Alkemy Protocol

> Alkemy On-Chain Protocol for Ethereum

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

Development requires you have the following pre-installed on your system:

1. [conda](https://docs.anaconda.com/anaconda/install/)
1. [ganache-cli](https://www.npmjs.com/get-np://github.com/trufflesuite/ganache-cli)

Once you have the `conda` and `npm` binaries installed and available on your PATH you can continue with the steps below to finish setting up your development environment.

> The following steps assume you are using a UNIX-like shell

```bash
# clone the repository
$ git clone https://github.com/Guardians-of-wallets/alkemy-protocol.git 
$ cd alkemy-protocol
```

```bash
# create the conda environment
$ conda env create -f environment.yml
$ conda activate alkemy-protocol
```

```bash
# install ganache-cli globally via npm
$ sudo npm install --global ganache-cli
```

> `ganache-cli` is a dependency of `eth-brownie`, check out the `eth-brownie` project documenation for more information by [clicking here](https://github.com/eth-brownie/brownie)

```bash
# install git hooks
$ pre-commit install
$ pre-commit install --hook-type commit-msg
```
