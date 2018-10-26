---
eip: 918
title: ERC-918 Minable Token Standard
author: Jay Logelin <jlogelin@fas.harvard.edu>, Infernal_toast <admin@0xbitcoin.org>, Michael Seiler <mgs33@cornell.edu>, Brandon Grill <bg2655@columbia.edu>, Rick Park <ceo@xbdao.io>
type: Standards Track
category: ERC
status: Draft
created: 2018-10-23
---

## Simple Summary

A specification for a standardized minable Token that uses a Proof of Work algorithm for distribution.


## Abstract

The following standard allows for the implementation of a standard API for tokens within smart contracts when including a POW (Proof of Work) mining distribution facility.
In this kind of token contract, tokens are locked within the token smart contract and slowly dispensed by means of a `mint()` function which acts like a POW faucet when the user submit a valid solution of some Proof of Work algorithm. The tokens are dispensed in chunks formed by some tokens ('reward').


## Motivation

The rationale for this model is that this approach can both minimize the gas fees paid by miners in order to obtain tokens and precisely control the distribution rate.
The standardization of the API will allow the development of standardized CPU and GPU token mining software, token mining pools and other external tools in the token mining ecosystem.
This standard is intended to be integrable in any token smart contract which eventually implements any other EIP standard for the non-mining-related functions, like ERC20, ERC223, ERC721, etc.
It can be here mentioned that token distribution via POW is considered very interesting in order to minimize the investor's risks exposure related to eventual illicit behavior of the 'human actors' who launch and manage the distribution, like those implementing ICO's (Initial Coin Offer) and derivatives. The POW model can be totally realized by means of a smart contract, excluding human interferences.


## Specification
### Mandatory methods
**NOTES**:
 - The following specifications use syntax from Solidity compiler version `0.4.25`
 - Callers MUST handle `false` from any `returns (bool success)`.  Callers MUST NOT assume that `false` is never returned!

#### challengeNumber
Returns the current `challengeNumber`, i.e. a byte32 number to be included (with other elements, see later) in the POW algorithm input in order to synthesize a valid solution. It is expected that a new `challengeNumber` is generated after that the valid solution has been found and the reward tokens have been assigned.

```solidity
function challengeNumber() view public returns (bytes32)
```

**NOTES**: in a common implementation `challengeNumber` is calculated starting from some immutable data, like elements derived from some past ethereum blocks.


#### difficulty
Returns the current difficulty, i.e. a number useful to estimate (by means of some known algorithm) the mean time required to find a valid POW solution. It is expected that the `difficulty` varies if the smart contract controls the mean time between valid solutions by means of some control loop.

```solidity
function difficulty() view public returns (uint)
```

**NOTES**: in a common implementation, difficulty varies when computational power is added/subtracted to the network, in order to maintain stable the mean time between valid solutions found.


#### epochCount
Returns the current epoch, i.e. the number of successful minting operation so far (starting from zero).

```solidity
function epochCount() view public returns (uint)
```

#### adjustmentInterval
Returns the interval, in seconds, between two successive difficulty adjustment.

```solidity
function adjustmentInterval () view public returns (uint)
```
**NOTES**: in a common implementation, while `difficulty` varies when computational power is added/subtracted to the network, the `adjustmentInterval` is fixed at deploy time.


#### miningTarget
Returns the `miningTarget`, i.e. a number which is a threshold useful to evaluate if a given submitted POW solution is valid.

```solidity
function miningTarget () view public returns (uint)
```

**NOTES**: in a common implementation, the solution is accepted if lower than the `miningTarget`.

#### miningReward
Returns the number of tokens that POW faucet shall dispense as next reward.

```solidity
function miningReward() view public returns (uint)
```

**NOTES**: in a common implementation, the reward progressively diminishes toward zero trough the epochs (“epoch” is the mining cycle started by the generation of a new `challengeNumber` and ended by the `reward` assignment), in order to have a maximum number of tokens dispensed in the whole life of the token smart contract, i.e. after that the maximum number of tokens has been dispensed, no more tokens will be dispensed.

#### tokensMinted
Returns the total number of tokens dispensed so far by POW faucet

```solidity
function tokensMinted() view public returns (uint)
```

#### mint
Returns a flag indicating that the submitted solution has been considered the valid solution for the current epoch and rewarded, and that all the activities needed in order to launch the new epoch have been successfully completed.

```solidity
function mint(uint nonce) public returns (bool success)
```

**NOTES**:

1) In particular, the method `mint()` verifies a submitted solution (`hash check`), described by the `nonce` (see later):

* `IF (the solution found is valid and it is the first valid solution submitted for the current epoch)`:
a) rewards the solution submitted sending No. `miningReward` tokens to `msg.sender`;
b) emit the Mint event;
c) creates a new `challengeNumber` valid for the next POW epoch;
d) eventually adjusts the POW difficulty;
e) returns true.
* `ELSE returns false` (or, in very common implementation, **reverts**).

2) The first phase (`hash check`) **MUST BE** implemented using the below specified public function `hash()`;
3) It is below defined a recommended (i.e. not mandatory) internal structure for the `mint()`, which should be adopted if there are not contrary reasons.

#### hash
Returns the digest calculated by the algorithm of hashing used in the particular implementation, whatever it be.

```solidity
function hash(uint nonce, address minter, bytes32 challengeNumber) public returns (bytes32 digest)
```

**NOTES**: `hash()` is to be declared `public` and it MUST include explicitly `uint nonce, address minter, bytes32 challengeNumber` in order to be useful as test function for the mining software development and debugging as well.


### Events
#### Mint
The `Mint` event indicates the rewarded address, the reward amount, the epoch count and the `challengeNumber` used in order to find the solution.

```solidity
event Mint(address indexed _to, uint _reward, uint _epochCount, bytes32 _challengeNumber)
```

**NOTES**: TO BE MANDATORY EMITTED immediately after that the submitted solution is rewarded.


## Recommendation

### MITM attacks
To prevent man-in-the-middle attacks, the `msg.sender` address, which is the address eventually rewarded, should be part of the hash so that any `nonce` solution found is valid only for that particular Ethereum account and it is not susceptible to be used by other. This also allows pools to operate without being easily cheated by the miners because pools can force miners to mine using the pool’s address in the hash algorithm. In that a case, indeed, the pool is the only address able to collect rewards.

### Anticipated mining
In order to avoid that miners are in condition to calculate anticipated solutions for later epoch, a `challengeNumber`, i.e. a number somehow derived from already existing and absolutely stable conditions, should be part of the hash so that future blocks cannot be mined before. The `challengeNumber` acts like a random piece of data that is not revealed until a mining round starts.

### Hash functions
The use of solidity `keccak256` algorithm is strongly recommended, even if not mandatory, because it is a very cost effective one-way algorithm to compute in the EVM environment and it is available as built-in function in solidity.

### Solution representation
The recommended representation of the solution found is by a `nonce`, i.e. a number, that miners try to find, that being part of the digest make the value of the hash of the digest itself under the required threshold for validity.

### mint() recommended internal structure
From the miner point of view, submitting a solution for possible reward means to call the `mint()` function with the suitable arguments and waiting for the result evaluation.
It is recommended that, internally, the `mint()` function be realized invoking 4 separate successive phases: hash check, rewarding, epoch increment, difficulty adjustment.
The first phase (hash check) **MUST BE** implemented using the above specified `public function hash()`, while the following internal `function mint()` structure is **strongly** recommended, but it is not mandatory. In particular the following phases, being totally internal to the contract, are not specified about calling parameters, but the pattern where four explicit and subsequent phases are evidenced (hash check, rewarding, epoch increment and difficulty adjustment) is **strongly** recommended.

In the preferred realization, for each of those steps a suitable function is declared and called:
1) hash check -> MANDATORY by above spec. 	`function hash()`
2) rewarding -> by means of some 		`function _reward() internal returns (uint)`
3) epoch increment -> by means of some 	`function _epoch() internal returns (uint)`
4) difficulty adj. -> by means of some 	`function _adjustDifficulty() internal returns (uint)`

It may be useful to recall that a `Mint` event MUST BE emitted after the rewarding phase, before returning the boolean `success` flag.

In a sample compliant realization, the `mint` can be then **roughly** described as follows:

```solidity
function mint(uint nonce) public returns (bool success) {
    require (uint(hash(nonce, minter, challengeNumber) <= miningTarget, “Invalid solution”);
    emit Mint(minter, _reward(), epochCount, challengeNumber;
    _epoch();
    _adjustDifficulty();
    return(true);
}
```

### Merged mining
Merged mining (i.e. the possibility to obtain multiple tokens reward by means of the same POW solution found) is nor mandatory, nor recommended, but in the case that a merge mining facility have to be implemented, it is **MANDATORY** to implement it by means of a dedicated methods, as follows:

```solidity
function merge(uint nonce, bytes32 challenge_digest, address[] mineTokens) public returns (bool success);
```

It is a method operationally very similar to the `mint()` methods, except that in the `merge()` a list of token target addresses is intended to be used to merge the multiple token rewards.

## Backwards Compatibility
In order to facilitate the use of both existing mining programs and existing pool software already used to mine any token deployed before the emission of the present standard, the following functions can be included in the contract. They are simply a wrapping of some of the above defined functions:

```solidity
function getAdjustmentInterval() public view returns (uint) {
            return adjustmentInterval();
}

function getChallengeNumber() public view returns (bytes32) {
            return challengeNumber();
}

function getMiningDifficulty() public view returns (uint) {
            return difficulty();
}
function getMiningReward() public view returns (uint) {
            return miningReward();
}

function mint(uint _nonce, bytes32 _challenge_digest) public returns (bool success) {
            return mint (_nonce);
}
```

**NOTES**: Any already existing token implementing this interface can be declared compliant to EIP918-B (B for Backwards). **EIP918-B compliance is deprecated.**

## Implementation notes and examples
here, properly reorganized, all the suitable elements from the current draft (interface, abstract contract, etc.)

### Abstract contract
In order to implement the standard, the following abstract contract can be included and inheritated by the smart contract.

```solidity
contract AEIP918B  {
  function challengeNumber() public view returns (bytes32);
  function difficulty() public view returns (uint);
  function epochCount() public view returns (uint);
  function adjustmentInterval () public view returns (uint);
  function miningTarget () public view returns (uint);
  function miningReward() public view returns (uint);
  function tokensMinted() public view returns (uint);
  function mint(uint nonce) public returns (bool success);
  function hash(uint nonce, address minter, bytes32 challengeNumber) public returns (bytes32 digest);
  event Mint(address indexed _to, uint _reward, uint _epochCount, bytes32 _challengeNumber);
}
```

**NOTES**: given that the **current** version of the solidity compiler (0.4.25) is not yet able to manage implicit public variables getter as valid overloads on interfaces and abstract contracts, to include the previous version of the abstract contract in order to be compliant can result in syntax errors if the smart contract overloading functions are intended to be the automatically created (by the compiler, at compile time) getter for public variables with the same name. The current solutions are: (i) to move public variables declarations in the abstract contract and to omit the related getter method declaration, or (ii) to name the public variable differently and to write the getter using the naming convention above declared by this standard.


#### Test Cases
-
-
-

## History

Historical links related to this standard:

- Original proposal from Jay Logelin: https://github.com/ethereum/wiki/wiki/Some
- Reddit discussion: https://www.reddit.com/r/ethereum/comments/3n8fkn/some/
- Original Issue EIP918: https://github.com/ethereum/EIPs/issues/918/some
-
-


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
