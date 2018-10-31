---
eip: 918
title: Mineable Token Standard
author: Jay Logelin <jlogelin@fas.harvard.edu>, Infernal_toast <admin@0xbitcoin.org>, Michael Seiler <mgs33@cornell.edu>, Brandon Grill <bg2655@columbia.edu>, Rick Park <ceo@xbdao.io>
type: Standards Track
category: ERC
status: Draft
created: 2018-10-31
---

### Simple Summary

A specification for a standardized Mineable Token that uses a Proof of Work algorithm for distribution.

### Abstract

This specification describes a method for initially locking tokens within a token contract and slowly dispensing them with a mint() function which acts like a faucet. This mint() function uses a Proof of Work algorithm in order to minimize gas fees and control the distribution rate. Additionally, standardization of mineable tokens allow for homogenous CPU and GPU token mining software, token mining pools and other external tools in the token mining ecosystem.

### Motivation

Token distribution via the ICO model and its derivatives is susceptible to illicit behavior by human actors. Furthermore, new token projects are centralized because a single entity must handle and control all of the initial coins and all of the raised ICO money.  By distributing tokens via an 'Initial Mining Offering' (or IMO), the ownership of the token contract no longer belongs with the deployer at all and the deployer is 'just another user.' As a result, investors risk exposure utilizing a mined token distribution model is significantly diminished. This standard is intended to be standalone, allowing maximum interoperability with ERC20, ERC223, ERC721, and others.

### Specification

#### Interface
The general behavioral specification includes a primary function that defines the token minting operation, an optional merged minting operation for issuing multiple tokens, getters for challenge number, mining difficulty, mining target and current reward, and finally a Mint event, to be emitted upon successful solution validation and token issuance. At a minimum, contracts must adhere to this interface (save the optional merge operation). It is recommended that contracts interface with the more behaviorally defined Abstract Contract described below, in order to leverage a more defined construct, allowing for easier external implementations via overridden phased functions. (see 'Abstract Contract' below)

``` solidity
interface ERC918Interface {
    function challengeNumber() external returns (bytes32);
    function miningTarget() external returns (uint256);
    function miningReward() external returns (uint256);
    function epochCount() external returns (uint);
    function tokensMinted() external returns (uint);
    function difficulty() external returns (uint256);
    function blocksPerReadjustment() external returns (uint);
    function mint(uint256 nonce) external returns (bool success);
    event Mint(address indexed from, uint rewardAmount, uint epochCount, bytes32 newChallengeNumber);
}
```

### Mandatory methods
**NOTES**:
 - The following specifications use syntax from Solidity compiler version `0.4.25`
 - Callers MUST handle `false` from any `returns (bool success)`.  Callers MUST NOT assume that `false` is never returned!

#### `challengeNumber`
Returns the current `challengeNumber`, i.e. a byte32 number to be included (with other elements, see later) in the POW algorithm input in order to synthesize a valid solution. It is expected that a new `challengeNumber` is generated after that the valid solution has been found and the reward tokens have been assigned.

```solidity
function challengeNumber() external public returns (bytes32)
```

**NOTES**: in a common implementation `challengeNumber` is calculated starting from some immutable data, like elements derived from some past ethereum blocks.


#### `miningTarget`
Returns the `miningTarget`, i.e. a number which is a threshold useful to evaluate if a given submitted POW solution is valid.

```solidity
function miningTarget () external public returns (uint)
```

**NOTES**: in a common implementation, the solution is accepted if lower than the `miningTarget`.

#### `miningReward`
Returns the number of tokens that POW faucet shall dispense as next reward.

```solidity
function miningReward() view external returns (uint)
```

**NOTES**: in a common implementation, the reward progressively diminishes toward zero trough the epochs (“epoch” is the mining cycle started by the generation of a new `challengeNumber` and ended by the `reward` assignment), in order to have a maximum number of tokens dispensed in the whole life of the token smart contract, i.e. after that the maximum number of tokens has been dispensed, no more tokens will be dispensed.

#### `epochCount`
Returns the current epoch, i.e. the number of successful minting operation so far (starting from zero).

```solidity
function epochCount() external public returns (uint)
```

#### `tokensMinted`
Returns the total number of tokens dispensed so far by POW contract

```solidity
function tokensMinted() external public returns (uint)
```

#### `difficulty`
Returns the current difficulty, i.e. a number useful to estimate (by means of some known algorithm) the mean time required to find a valid POW solution. It is expected that the `difficulty` varies if the smart contract controls the mean time between valid solutions by means of some control loop.

```solidity
function difficulty() external public returns (uint)
```

**NOTES**: in a common implementation, difficulty varies when computational power is added/subtracted to the network, in order to maintain stable the mean time between valid solutions found.

#### `blocksPerReadjustment`
Returns the number of token block rewards between difficulty readjustment.

```solidity
function blocksPerReadjustment() external returns (uint);
```
**NOTES**: in a common implementation, while `difficulty` varies when computational power is added/subtracted to the network, the `blocksPerReadjustment` is fixed at deploy time.


#### `mint`
Returns a flag indicating that the submitted solution has been considered the valid solution for the current epoch and rewarded, and that all the activities needed in order to launch the new epoch have been successfully completed.

```solidity
function mint(uint nonce) external returns (bool success)
```

**NOTES**:

1) In particular, the method `mint()` verifies a submitted solution (`solution validity check`), described by the `nonce` (see later):

* `IF (the solution found is valid and it is the first valid solution submitted for the current epoch)`:
a) rewards the solution submitted sending No. `miningReward` tokens to `msg.sender`;
b) emit the Mint event;
c) creates a new `challengeNumber` valid for the next POW epoch;
d) eventually adjusts the POW difficulty;
e) returns true.
* `ELSE returns false` (or, in very common implementation, **reverts**).

2) The first phase (`solution validity check`) **MUST BE** implemented using in the code the below specified public function `hash()`;
3) It is below defined a recommended (i.e. not mandatory) internal structure for the `mint()`, which should be adopted if there are not contrary reasons (see below: `mint() recommended internal architecture)`

#### `hash`
Returns the digest calculated by the algorithm of hashing used in the particular implementation, whatever it be.

```solidity
function hash(uint nonce, address minter, bytes32 challengeNumber) public returns (bytes32 digest)
```

**NOTES**: `hash()` is to be declared `public` and it MUST include explicitly `uint nonce, address minter, bytes32 challengeNumber` in order to be useful as test function for the mining software development and debugging as well.


### Events
#### `Mint`
The `Mint` event indicates the rewarded address, the reward amount, the epoch count and the `challengeNumber` used in order to find the solution.

```solidity
event Mint(address indexed _to, uint _reward, uint _epochCount, bytes32 _challengeNumber)
```

**NOTES**: TO BE MANDATORY EMITTED immediately after that the submitted solution is rewarded.

## RECOMMENDATION

### MITM attacks
To prevent man-in-the-middle attacks, the `msg.sender` address, which is the address eventually rewarded, can be part of the hash so that any `nonce` solution found is valid only for that particular Ethereum account and it is not susceptible to be used by other. To enforce trust between pools and miners, there is a recommended delegated mining scheme that can additionally be used, that allows miners to safely submit signed solutions to pools who submit on behalf of the original miners. ( See 'Delegated Minting Extension' )

### Anticipated mining
In order to avoid that miners are in condition to calculate anticipated solutions for later epoch, a `challengeNumber`, i.e. a number somehow derived from already existing and absolutely stable conditions, should be part of the hash so that future blocks cannot be mined before. The `challengeNumber` acts like a random piece of data that is not revealed until a mining round starts.

### Hash functions
The use of solidity `keccak256` algorithm is strongly recommended, although not mandatory, because it is a very cost effective one-way algorithm to compute in the EVM environment and it is available as built-in function in solidity.

### Solution representation
The recommended representation of the solution found is by a `nonce`, i.e. a number, that miners try to find, that being part of the digest make the value of the hash of the digest itself under the required threshold for validity.

### Bitcoin like POW models
In the case that a POW model similar to that of bitcoin is adopted (i.e. evaluation of solution validity based on being lower or equal of a given threshold and cited threshold moved between a maximum and a minimum) it is **STRONGLY RECCOMENDED** that both the upper limit and the lower limit of the threshold swing, be accessible from the interface. Two additional methods should be implemented:

**`MIN_TARGET`**
Returns the minimum possible target that the mineable contract will provide as part of the proof of work algorithm.

```solidity
function MIN_TARGET() external public returns (uint256)
```

**`MAX_TARGET`**
Returns the maximum possible target that the mineable contract will provide as part of the proof of work algorithm.

```solidity
function MAX_TARGET() external public returns (uint256)
```

### mint() recommended internal architecture
From the miner's point of view, submitting a solution for possible reward means calling the `mint()` function with the `nonce` argument and waiting for the result evaluation.
It is recommended that, internally, the `mint()` function be realized invoking 4 separate successive phases: solution validity check, rewarding, epoch increment, difficulty adjustment.
The use in the first phase (solution validity check) of the above specified hash() function is **MANDATORY** (in order to assure full consistency between SW developed for mining and the solution validity check).

The following `function mint()` internal architecture is recommended, but not mandatory:
1. validity check -> by means of some	`function _hashCheck()`
2. solution rewarding -> by means of some 		`function _reward() internal returns (uint)`
3. epoch increment -> by means of some 	`function _epoch() internal returns (uint)`
4. difficulty adj. -> by means of some 	`function _adjustDifficulty() internal returns (uint)`

It may be useful to recall that a `Mint` event MUST BE emitted just after the rewarding phase, in evry case before returning the boolean `success` flag.

In a sample compliant realization, the `mint` can be then **roughly** described as follows:

```solidity
function mint(uint256 nonce) public returns (bool success)
{
    _hashCheck(hash(nonce, msg.sender, challengeNumber));
    _reward();
    emit Mint(minter, _reward(), epochCount, challengeNumber);
    _epoch();
    _adjustDifficulty();
    return true;
}
```

### Example of mining function
A general mining function written in python for finding a valid nonce for keccak256 mined token, is as follows:
``` python
def generate_nonce():
  myhex =  b'%064x' % getrandbits(32*8)
  return codecs.decode(myhex, 'hex_codec')

def mine(challenge, public_address, difficulty):
  while True:
    nonce = generate_nonce()
    hash1 = int(sha3.keccak_256(challenge+public_address+nonce).hexdigest(), 16)
    if hash1 < difficulty:
      return nonce
```

Once the nonce and hash1 are found, these are used to call the mint() function of the smart contract to receive a reward of tokens.

### Merged Mining Extension (Optional)
In order to provide support for merge mining multiple tokens, an optional merged mining extension can be implemented as part of the ERC918 standard. It is important to note that the following function will only properly work if the base contracts use tx.origin instead of msg.sender when applying rewards. If not the rewarded tokens will be sent to the calling contract and not the end user.

``` solidity
/**
 * @title ERC-918 Mineable Token Standard, optional merged mining functionality
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md
 *
 */
contract ERC918Merged is AbstractERC918 {
    /*
     * @notice Externally facing merge function that is called by miners to validate challenge digests, calculate reward,
     * populate statistics, mutate state variables and adjust the solution difficulty as required. Additionally, the
     * merge function takes an array of target token addresses to be used in merged rewards. Once complete,
     * a Mint event is emitted before returning a success indicator.
     *
     * @param _nonce the solution nonce
     **/
    function merge(uint256 _nonce, address[] _mineTokens) public returns (bool) {
      for (uint i = 0; i < _mineTokens.length; i++) {
        address tokenAddress = _mineTokens[i];
        ERC918Interface(tokenAddress).mint(_nonce);
      }
    }

    /*
     * @notice Externally facing merge function kept for backwards compatability with previous definition
     *
     * @param _nonce the solution nonce
     * @param _challenge_digest the keccak256 encoded challenge number + message sender + solution nonce
     **/
     function merge(uint256 _nonce, bytes32 _challenge_digest, address[] _mineTokens) public returns (bool) {
       //the challenge digest must match the expected
       bytes32 digest = keccak256( abi.encodePacked(challengeNumber, msg.sender, _nonce) );
       require(digest == _challenge_digest, "Challenge digest does not match expected digest on token contract [ ERC918Merged.mint() ]");
       return merge(_nonce, _mineTokens);
     }
}
```

### Delegated Minting Extension (Optional)
In order to facilitate a third party minting submission paradigm, such as the case of miners submitting solutions to a pool operator and/or system, a delegated minting extension can be used to allow pool accounts submit solutions on the behalf of a user, so the miner can avoid directly paying Ethereum transaction costs. This is performed by an off chain mining account packaging and signing a standardized mint solution packet and sending it to a pool or 3rd party to be submitted.

The ERC918 Mineable Mint Packet Metadata should be prepared using following schema:
``` solidity
{
    "title": "Mineable Mint Packet Metadata",
    "type": "object",
    "properties": {
        "nonce": {
            "type": "string",
            "description": "Identifies the target solution nonce",
        },
        "origin": {
            "type": "string",
            "description": "Identifies the original user that mined the solution nonce",
        },
        "signature": {
            "type": "string",
            "description": "The signed hash of tightly packed variables sha3('delegatedMintHashing(uint256,address)')+nonce+origin_account",
        }
    }
}
```
The preparation of a mineable mint packet on a JavaScript client would appear as follows:

``` solidity
function prepareDelegatedMintTxn(nonce, account) {
  var functionSig = web3.utils.sha3("delegatedMintHashing(uint256,address)").substring(0,10)
  var data = web3.utils.soliditySha3( functionSig, nonce, account.address )
  var sig = web3.eth.accounts.sign(web3.utils.toHex(data), account.privateKey )
  // prepare the mint packet
  var packet = {}
  packet.nonce = nonce
  packet.origin = account.address
  packet.signature = sig.signature
  // deliver resulting JSON packet to pool or third party
  var mineableMintPacket = JSON.stringify(packet, null, 4)
  /* todo: send mineableMintPacket to submitter */
  ...
}
```
Once the packet is prepared and formatted it can then be routed to a third party that will submit the transaction to the contract's delegatedMint() function, thereby paying for the transaction gas and receiving the resulting tokens. The pool/third party must then manually payback the minted tokens minus fees to the original minter.

The following code sample exemplifies third party packet relaying:
``` solidity
//received by minter
var mineableMintPacket = ...
var packet = JSON.parse(mineableMintPacket)
erc918MineableToken.delegatedMint(packet.nonce, packet.origin, packet.signature)
```
The Delegated Mint Extension expands upon ERC918 realized as a sub-contract:
``` js
import 'openzeppelin-solidity/contracts/contracts/cryptography/ECDSA.sol';

contract ERC918DelegatedMint is AbstractERC918, ECDSA {
   /**
     * @notice Hash (keccak256) of the payload used by delegatedMint
     * @param _nonce the golden nonce
     * @param _origin the original minter
     * @param _signature the original minter's eliptical curve signature
     */
    function delegatedMint(uint256 _nonce, address _origin, bytes _signature) public returns (bool success) {
        bytes32 hashedTx = delegatedMintHashing(_nonce, _origin);
        address minter = recover(hashedTx, _signature);
        require(minter == _origin, "Origin minter address does not match recovered signature address [ AbstractERC918.delegatedMint() ]");
        require(minter != address(0), "Invalid minter address recovered from signature [ ERC918DelegatedMint.delegatedMint() ]");
        success = mintInternal(_nonce, minter);
    }

    /**
     * @notice Hash (keccak256) of the payload used by delegatedMint
     * @param _nonce the golden nonce
     * @param _origin the original minter
     */
    function delegatedMintHashing(uint256 _nonce, address _origin) public pure returns (bytes32) {
        /* "0x7b36737a": delegatedMintHashing(uint256,address) */
        return toEthSignedMessageHash(keccak256(abi.encodePacked( bytes4(0x7b36737a), _nonce, _origin)));
    }
}
```

### Mineable Token Metadata (Optional)
In order to provide for richer and potentially mutable metadata for a particular Mineable Token, it is more viable to offer an off-chain reference to said data. This requires the implementation of a single interface method 'metadataURI()' that returns a JSON string encoded with the string fields symbol, name, description, website, image, and type.

Solidity interface for Mineable Token Metadata:
``` solidity
/**
 * @title ERC-918 Mineable Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md
 *
 */
interface ERC918Metadata is AbstractERC918 {
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a mineable asset.
     */
    function metadataURI() external view returns (string);
}
```

Mineable Token Metadata JSON schema definition:
``` solidity
{
    "title": "Mineable Token Metadata",
    "type": "object",
    "properties": {
        "symbol": {
            "type": "string",
            "description": "Identifies the Mineable Token's symbol",
        },
        "name": {
            "type": "string",
            "description": "Identifies the Mineable Token's name",
        },
        "description": {
            "type": "string",
            "description": "Identifies the Mineable Token's long description",
        },
        "website": {
            "type": "string",
            "description": "Identifies the Mineable Token's homepage URI",
        },
        "image": {
            "type": "string",
            "description": "Identifies the Mineable Token's image URI",
        },
        "type": {
            "type": "string",
            "description": "Identifies the Mineable Token's hash algorithm ( ie.keccak256 ) used to encode the solution",
        }
    }
}
```


### Backwards Compatibility
#### mint()
Earlier versions of this standard incorporated a redundant 'challenge_digest' parameter on the mint() function that hash-encoded the packed variables challengeNumber, msg.sender and nonce. It was decided that this could be removed from the standard to help minimize processing and thereby gas usage during mint operations.

#### Compiler limitations
Given that the **current** version of the solidity compiler (0.4.25) is not yet able to manage implicit public variables getter as valid overloads on interfaces and abstract contracts, to include the previous version of the abstract contract in order to be compliant can result in syntax errors if the smart contract overloading functions are intended to be the automatically created (by the compiler, at compile time) getter for public variables with the same name. The current solutions are: (i) to move public variables declarations in the abstract contract and to omit the related getter method declaration, or (ii) to name the public variable differently and to write the getter using the naming convention above declared by this standard.

#### Inheritance
Therefore, in the name of interoperability with existing mining programs and pool software the following contracts can be added to the inheritance tree of an ERC918 token and expect to be fully compatible with existing software.

**NOTES**: Any already existing token implementing this interface can be declared compliant to EIP918-B (B for backwards compatible). **EIP918-B compliance is deprecated.**

```solidity
interface EIP918-B  {
   function getChallengeNumber() external view returns (bytes32);
   function getMiningDifficulty() external view returns (uint);
   function getMiningTarget() external view returns (uint);
   function getMiningReward() external view returns (uint);
   function mint(uint256 nonce, bytes32 challenge_digest) external returns (bool success);
   event Mint(address indexed _to, uint _reward, uint _epochCount, bytes32 _challengeNumber);
}
```

``` solidity
/**
 * @title ERC-918 Mineable Token Standard, optional backwards compatibility function
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md
 *
 */
contract ERC918BackwardsCompatible is EIP918-B /* ,ERC918TokenImpl */ {

    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber();
    }

    function getMiningDifficulty() public view returns (uint) {
        return difficulty();
    }

    function getMiningTarget() public view returns (uint) {
        return miningTarget();
    }

    function getMiningReward() public view returns (uint) {
        return miningReward();
    }

    /*
     * @notice Externally facing mint function kept for backwards compatibility with previous mint() definition
     * @param _nonce the solution nonce
     * @param _challenge_digest the keccak256 encoded challenge number + message sender + solution nonce
     **/
    function mint(uint256 _nonce, bytes32 _challenge_digest) public returns (bool success) {
        //the challenge digest must match the expected
        bytes32 digest = keccak256( abi.encodePacked(challengeNumber, msg.sender, _nonce) );
        require(digest == _challenge_digest, "Challenge digest does not match expected digest on token contract [ ERC918BackwardsCompatible.mint() ]");
        success = mint(_nonce);
    }
}
```

### Test Cases
(Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.)


### Implementation
0xBitcoin Token Contract (first standard implementation):
https://etherscan.io/address/0xb6ed7644c69416d67b522e20bc294a9a9b405b31

Simple Example:
https://github.com/0xbitcoin/EIP918-Mineable-Token/blob/master/contracts/SimpleERC918.sol

Complex Examples:

https://github.com/0xbitcoin/EIP918-Mineable-Token/blob/master/contracts/0xdogeExample.sol
https://github.com/0xbitcoin/EIP918-Mineable-Token/blob/master/contracts/0xdogeExample2.sol
https://github.com/0xbitcoin/EIP918-Mineable-Token/blob/master/contracts/0xBitcoinBase.sol

MVI OpenCL Token Miner
https://github.com/mining-visualizer/MVis-tokenminer/releases

PoWAdv Token Contract:
https://etherscan.io/address/0x1a136ae98b49b92841562b6574d1f3f5b0044e4c

### Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
