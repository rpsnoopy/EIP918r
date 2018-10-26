pragma solidity ^0.4.25;

/**
 * @title IEIP918 interface
 * @dev see https://github.com/ethereum/EIPs/issues/918
 */

interface IEIP918  {

    // challengeNumber() Returns the current challengeNumber, i.e. a byte32 number to be included in the POW algorithm input in order
    // to synthetize a valid solution. It is expected that a new challengeNumber is generated after that the valid solution has been
    // found and the reward tokens have been assigned.
    function challengeNumber() external view returns (bytes32);

    // difficulty() Returns the current difficulty, i.e. a number useful to estimate (by means of some known algorithm) the mean time
    // required to find a valid POW solution. It is expected that the difficulty varies if the smart contract controls the mean time
    // between valid solutions by means of some control loop.
    function difficulty() external view returns (uint256);

    // epochCount() Returns the current epoch, i.e. the number of successful minting operation so far (starting from zero).
    function epochCount() external view returns (uint256);

    // adjustmentInterval() Returns the interval, in seconds, between two successive difficulty adjustment.
    function adjustmentInterval () external view returns (uint256);

    // miningTarget() Returns the miningTarget, i.e. a number which is a threshold useful to evaluate if a given submitted POW solution is valid.
    function miningTarget () external view returns (uint256);

    // miningReward() Returns the number of tokens that POW faucet shall dispense as next reward.
    function miningReward() external view returns (uint256);

    // tokensMinted() Returns the total number of tokens dispensed so far by POW faucet
    function tokensMinted() external view returns (uint256);

    // mint() Returns a flag indicating that the submitted solution has been considered the valid solution for the current epoch and
    // rewarded, and that all the activities needed in order to launch the new epoch have been successfully completed.
    // In particular, the method verifies a submitted solution, described by the nonce:
    // -> If the solution found is the first valid solution submitted for the current epoch:
    //    - rewards the solution found sending No. miningReward tokens to msg.sender;
    //    - creates a new challengeNumber valid for the next POW epoch;
    //    - eventually adjusts the POW difficulty;
    //    - return true
    // -> If the solution is not the first valid solution submitted for the current epoch, it returns false (or revert)
    function mint(uint256 nonce) external returns (bool success);

    //hash() Returns the digest calculated by the algorithm of hashing used in the particular implementation, whatever it will be.
    // The function is to be declared public and to be written including explicitly
    // uint256 nonce, address minter, bytes32 challengeNumber
    // in order to be useful as test function for mining software development and debugging as well.
    function hash(uint256 nonce, address minter, bytes32 challengeNumber) external returns (bytes32 digest);

    // event Mint() TO BE MANDATORY EMITTED immediately after that the submitted solution is rewarded.
    // The Mint event indicates the rewarded address, the reward amount, the epoch count and the challenge number used.
    event Mint(
		address indexed _to,
		uint _reward,
		uint _epochCount,
		bytes32 _challengeNumber
	);

} //END OF EIP918 INTERFACE
