# Fiat-to-Crypto Payment Processing Protocol(PPP) - MVP

# About

The ***Fiat-to-Crypto Payment Processing Protocol(PPP)*** is a smart contract system designed to process FIAT payments in blockchain powered applications. The result will be credit card payments settled into cryptocurrency, more explicitly into stablecoins.

The goal is for users to pay with a credit card when buying digital assets and remove the need of connecting a wallet.

As crypto-wallets need an above the average technical know-how for operation(set-up, secure pass-phrase, funding, connecting), this project is intended to allow more individuals to aquire and use blockchain related products, increasing overall adoption.

## Description

This service is intended for C2B and B2B payments, in blockchain applications like digital assets e-commerce/trading, payments for services/subscriptions or other use cases.  

In order to better understand how the Fiat-to-Crypto Payment Processing works, the MVP makes use of a ticketing platform that sells entrance tickets as NFTs. 

There is no website that sells tickets, but to mimick and simplify the buying process we go straight to the  Stripe payment checkout page.

Actors: 

  1. Admin/Owner - account that deploys the payment processor, sets/updates configuration and controls main functions
                 - can update processor implementation(can he?)
  2. Seller Platform - entity(smart contract/EOA) that owns and transfers digital assets, receives payments 
                           - for this MVP seller = admin
  3. Buyer - consumer paying with credit card, address filled in at checkout

## How it works

### Setup

***Admin:***

- Deploys ProcessorAddressProvider
- Deploys Procesor
- Sets Processor Implementation
- Funds Processor with stablecoin

***Seller:***

- Approves Processor to transfer NFTs

### Payment Flow:

```
    BUYER                      STRIPE                     BLOCKCHAIN
      │                          │                            │
      │  1. Opens payment link   │                            │
      │  2. Enters wallet address│                            │
      │  3. Pays with card    │                            │
      │ ────────────────────────►│                            │
      │                          │                            │
      │                          │  4. Payment confirmed      │
      │                          │  5. Webhook sent           │
      │                          │ ──────────────────────────►│
      │                          │                            │
      │                          │         6. Backend calls   │
      │                          │         processPayment()   │
      │                          │                            │
      │                          │                            │
      │◄─────────────────────────────────── 7. NFT delivered  │
      │                          │                            │
                                              │
                                              ▼
                                    8. USDC sent to Seller
```

Admin deploys the ProcessorAddressesProvider and 

### Key Features

- Users don't need to connect wallet
- Receiving metadata by email
- Faster buying process using Fiat
- Payment processing and setlement in stablecoins
- **Atomic swaps** - NFT and USDC transfer together or not at all
- **No buyer crypto** - Pay with any credit card
- **Instant settlement** - Seller receives USDC in ~15 seconds
- **Upgradeable** - Processor can be upgraded via proxy
- **Multi-stablecoin** - Supports USDC, USDT, DAI, etc.

## Properties

Bussiness will have the possibility to deploy their own Fiat-to-Crypto Payment Processor with custom configuration.

Configuration: 

1. Seller address
2. NFT contract addres
3. Stablecoin address

Configuration parameters will have the possibility to be updated after deployment. 

Idealy, the deploymenta dn configuration setup will be done through a frontend to simplify the process.

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - After installing run `git --version` and the result should be `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - After installing run `forge --version` and the result should be `forge x.x.x`

## Install Dependencies 

### Smart Contract

```
forge install smartcontractkit/chainlink-brownie-contracts

https://docs.openzeppelin.com/upgrades-plugins/foundry/foundry-upgrades
https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-foundry-upgrades
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```

### Backend 

```
cd ppp-backend
npm init -y
nom install npm install express stripe ethers dotenv readline-sync
```

## Quickstart

```
git clone https://github.com/MihaiHng/Payment-Processing-Protocol 
cd Payment-Processing-Protocol
forge build
```

## Backend Terminals 

```
Terminal 1: node server.js
Terminal 2: stripe listen --forward-to localhost:3000/webhook
```

## Testing 

### Static Analysis 

Slither Report:

### Coverage Report



### Test Suite

- Unit Tests
- Upgradeablity Tests
- Fuzz Tests
- Invariant Tests


## Future Improvements

1. In future iterations which will likely increase in complexity, consider using Chainlink Runtine Environment (CRE), to simplify the workflow between the different components of the system, onchain reads, offchain reads, onchain writes etc.
Opposed to the more simple current approach used for this MVP, Function + Automation

2. After MVP, replace ProcessAddressesProvider with a Factory for multi-seller usage/onboarding

3. Liquidity Pool focused on providing funding to deployed Processors that need funding. Admins can connect their deployed Processor to the Liquidity Pool for funding.

4. Addition of a fee/processed payment -> Use funds for development, optimization, scaling, marketing, maintainance
