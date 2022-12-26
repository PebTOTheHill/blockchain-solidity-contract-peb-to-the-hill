# Pleb Of The Hill

## Description

#### <i>Pleb Of The Hill</i> is a player-vs-player game built on Pulsechain Testnet that has <b>Many Winners, 1 Loser.</b> The objective of the game is to participate as frequently as possible in order to earn PLS (native token on Pulse) without being the last one standing.

## Techologies Used:

- Hardhat
- Solidity
- JavaScript

## How to install and deploy:

> - npm install
> - npx hardhat compile
> - npx hardhat run scripts/deploy.js --network testnet

## Contracts

### PlebToHill

This the main contract and has following methods.

| Name           | Functionality                                                                                                                             | Arguments    |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| createRound    | It is used to create a new round once the previous round is completed. This function can only be called by owner who has to deposit 1 PLS | N/A          |
| endRound       | It is used to end a live round once the round duration is over . This function can only be called by owner                                | roundId      |
| addParticipant | It is used to add participant to a live round and pay winnings to the previous participant whenever a new participant joins               | roundId      |
| setPothWallet  | It is used to set the Pleb of the hill wallet address to collect the service fee                                                          | \_pothwallet |
| getLoserData   | It is used to get the loser participant data once round is over                                                                           | roundId      |

### List of Libraries/Framework used:

- Mocha
- Chai

### Run Test Cases:

> npx hardhat test

### Run coverage report

> npx hardhat coverge

### Generate functional doc

> npx hardhat dodoc
