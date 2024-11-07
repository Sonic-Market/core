# Sonic Market

[![Docs](https://img.shields.io/badge/docs-%F0%9F%93%84-blue)](https://docs.sonic.market/)
[![CI status](https://github.com/Sonic-Market/core/actions/workflows/test.yaml/badge.svg)](https://github.com/Sonic-Market/core/actions/workflows/test.yaml)
[![Discord](https://img.shields.io/static/v1?logo=discord&label=discord&message=Join&color=blue)](https://discord.com/invite/sonic-market)
[![Twitter](https://img.shields.io/static/v1?logo=twitter&label=twitter&message=Follow&color=blue)](https://x.com/Sonic_Market)

Core Contract of Sonic Market

## Table of Contents

- [Sonic Market](#sonic-market)
    - [Table of Contents](#table-of-contents)
    - [Deployments](#deployments)
    - [Install](#install)
    - [Usage](#usage)
        - [Tests](#tests)
        - [Linting](#linting)
        - [Library](#library)
    - [Licensing](#licensing)

## Deployments

All deployments can be found in the [deployments](./deployments) directory.

## Install


### Prerequisites
- We use [Forge Foundry](https://github.com/foundry-rs/foundry) for test. Follow the [guide](https://github.com/foundry-rs/foundry#installation) to install Foundry.

### Installing From Source

```bash
git clone https://github.com/Sonic-Market/core && cd core
npm install
```

## Usage

### Tests
```bash
npm run test
```

### Linting

To run lint checks:
```bash
npm run prettier:ts
npm run lint:sol
```

To run lint fixes:
```bash
npm run prettier:fix:ts
npm run lint:fix:sol
```

### Library
To utilize the contracts, you can install the code in your repo with forge:
```bash
forge install https://github.com/Sonic-Market/core
```

## Licensing
- The primary license for Sonic Market is the Time-delayed Open Source Software Licence, see [License file](LICENSE.pdf).
- Interfaces are licensed under MIT (as indicated in their SPDX headers).
- Some [libraries](src/libraries) have a GPL license.
