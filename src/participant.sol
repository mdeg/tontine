pragma solidity ^0.4.21;

import "./tontine.sol";
import "./lib.sol";

// Contract for the participant of the tontine
contract Participant {

    // The owner account (i.e. the creator of the contract)
    address owner;
    // The address of the initial tontine that is receiving investment
    address tontineAddress;

    // The address of the running tontine that the funds have been invested in
    // This is received from the tontineAddress once it starts
    address runningTontineAddress;

    // Kick off the contract - requires a deployed tontine!
    // TODO: what if the tontine does not exist?
    constructor(address _tontineAddress) public {
        owner = msg.sender;

        tontineAddress = _tontineAddress;

        // TODO: send money to tontine to invest
    }

    // This contract has been notified that funds are available to collect
    // These funds must be collected before the expiry or the owner will be considered 'dead'
    function notify(uint expiry) external {
        require(msg.sender == runningTontineAddress);

        // TODO: how to notify owner?

        emit ReadyToCollect(now, expiry);
    }

    // Collect the dividends held in the running tontine
    // Requires an identity token from the oracle, given after providing proof-of-life
    function collect(bytes32 identityToken) external  {
        require(runningTontineAddress != 0);
        require(msg.sender == owner);

        RunningTontine(runningTontineAddress).retrieve(identityToken);

        // TODO: error handling
    }

    function invest() payable {
        Tontine(tontineAddress).invest();
        // TODO: functionality for investing more money
    }

    // Tontine has started but there was no money
    function cull() {
        require(msg.sender == tontineAddress);

        emit Culled();

        selfdestruct(owner);
    }

    // The tontine has begun - lock the funds
    function lock(address _runAddress) external {
        require(msg.sender == tontineAddress);

        runningTontineAddress = _runAddress;
        tontineAddress = 0;
    }

    // Cancel an investment in the tontine
    // Only valid if the tontine has not started - the funds are locked once that begins
    function cancel() external {
        require(msg.sender == owner);
        require(tontineAddress != 0);

        Tontine(tontineAddress).cancelInvestment();

        // TODO: test that the funds are returned to this contract

        selfdestruct(owner);
    }

    // The running tontine has instructed this contract to suicide due to inactivity and a failure to claim the share
    function devolve() external {
        require(msg.sender == runningTontineAddress);

        // emit event
        emit Devolved(address(this).balance, now);

        selfdestruct(runningTontineAddress);
    }

    // Events
    event ReadyToCollect(uint _ts, uint _expiry);
    event Devolved(uint _amount, uint _ts);
    event Culled();
}
