pragma solidity ^0.4.25;

/**
 * @title AEIP918 ABSTRACT CONTRACT
 * @dev see https://github.com/ethereum/EIPs/issues/918
 */

contract AEIP918B  {

    // challengeNumber() Returns the current challengeNumber, i.e. a byte32 number to be included in the POW algorithm input in order
    // to synthetize a valid solution. It is expected that a new challengeNumber is generated after that the valid solution has been
    // found and the reward tokens have been assigned.
    function challengeNumber() public view returns (bytes32);

    // difficulty() Returns the current difficulty, i.e. a number useful to estimate (by means of some known algorithm) the mean time
    // required to find a valid POW solution. It is expected that the difficulty varies if the smart contract controls the mean time
    // between valid solutions by means of some control loop.
    function difficulty() public view returns (uint256);

    // epochCount() Returns the current epoch, i.e. the number of successful minting operation so far (starting from zero).
    function epochCount() public view returns (uint256);

    // adjustmentInterval() Returns the interval, in seconds, between two successive difficulty adjustment.
    function adjustmentInterval () public view returns (uint256);

    // miningTarget() Returns the miningTarget, i.e. a number which is a threshold useful to evaluate if a given submitted POW solution is valid.
    function miningTarget () public view returns (uint256);

    // miningReward() Returns the number of tokens that POW faucet shall dispense as next reward.
    function miningReward() public view returns (uint256);

    // tokensMinted() Returns the total number of tokens dispensed so far by POW faucet
    function tokensMinted() public view returns (uint256);

    // mint() Returns a flag indicating that the submitted solution has been considered the valid solution for the current epoch and
    // rewarded, and that all the activities needed in order to launch the new epoch have been successfully completed.
    // In particular, the method verifies a submitted solution, described by the nonce:
    // -> If the solution found is the first valid solution submitted for the current epoch:
    //    - rewards the solution found sending No. miningReward tokens to msg.sender;
    //    - creates a new challengeNumber valid for the next POW epoch;
    //    - eventually adjusts the POW difficulty;
    //    - return true
    // -> If the solution is not the first valid solution submitted for the current epoch, it returns false (or revert)
    function mint(uint256 nonce) public returns (bool success);

    //hash() Returns the digest calculated by the algorithm of hashing used in the particular implementation, whatever it will be.
    // The function is to be declared public and to be written including explicitly
    // uint256 nonce, address minter, bytes32 challengeNumber
    // in order to be useful as test function for mining software development and debugging as well.
    function hash(uint256 nonce, address minter, bytes32 challengeNumber) public returns (bytes32 digest);

    // NOTE: ALL THE PREVIOUS FUNCTION HAVE TO BE MANDATORY OVERLOADED BY THE DEVELOPER

    // event Mint() TO BE MANDATORY EMITTED immediately after that the submitted solution is rewarded.
    // The Mint event indicates the rewarded address, the reward amount, the epoch count and the challenge number used.
    event Mint(
		address indexed _to,
		uint _reward,
		uint _epochCount,
		bytes32 _challengeNumber
	);

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// WRAPPING FOR BACKWARD COMPATIBILITY (EIP918B)
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// In order to facilitate the use of both existing mining programs and existing pool software already used to mine
	// previous minable tokens, here are defined some function which are a simple wrapping of some of above defined
	// functions by the definitions from the previous versions of the EIP918 standard (now defined EIP918-B).
	//
	// -> Any contract including this wrapping is compliant to both current EIP918 AND previous EIP918-B
	//
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

	function mint(uint256 _nonce, bytes32 _challenge_digest) public returns (bool success) {
		return mint (_nonce);
	}

	// NOTE: ALL THESE WRAPPING FUNCTION HAVE NOT TO BE MANDATORY OVERLOADED BY THE DEVELOPER


} //END OF EIP918 A&B ABSTRACT CONTRACT
