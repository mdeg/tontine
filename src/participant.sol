pragma solidity ^0.4.21;

import "./tontine.sol";
import "./lib.sol";

// Contract for the participant of the tontine
contract Participant {

    // The owner account (i.e. the address that manages this participant)
    address owner;

    // The address of the initial tontine that is receiving investment
    address tontineAddress;

    // The address of the running tontine that the funds have been invested in
    address runningTontineAddress;

    // Kick off the contract - requires a deployed tontine!
    constructor(address _tontineAddress) public {
        owner = msg.sender;

        tontineAddress = _tontineAddress;
    }

    // This contract has been notified that funds are available to collect
    // These funds must be collected before the expiry or the owner will be considered 'dead'
    function notify(uint expiry) external {
        require(msg.sender == runningTontineAddress);

        emit ReadyToCollect(now, expiry);
    }

    // Collect the dividends held in the running tontine
    // Requires an identity token from the oracle, given after providing proof-of-life
    function collect(bytes32 identityToken) external  {
        require(runningTontineAddress != 0);
        require(msg.sender == owner);

        RunningTontine(runningTontineAddress).retrieve(identityToken);

        msg.sender.transfer(address(this).balance);
    }

    // Invest some money into the tontine contract. Only valid before the tontine has started.
    function invest() external payable {
        require(tontineAddress == 0);
        require(runningTontineAddress != 0);

        Tontine(tontineAddress).invest();
        tontineAddress.transfer(address(this).balance);
    }

    // The tontine has started but no money was invested into it by this participant, so it has been culled
    // Suicide and return anything sitting in this contract back to the originator
    function cull() external {
        require(msg.sender == tontineAddress);

        emit Culled();

        selfdestruct(owner);
    }

    // The tontine has begun - lock up the funds funds
    function lock(address _runAddress) external {
        require(msg.sender == tontineAddress);

        runningTontineAddress = _runAddress;
        tontineAddress = 0;

        emit Locked(now);
    }

    // Cancel an investment in the tontine
    function cancel() external {
        require(msg.sender == owner);
        require(tontineAddress != 0);

        Tontine(tontineAddress).cancelInvestment();

        emit Cancelled();

        selfdestruct(owner);
    }

    // The share has been devolved due to an inability to collect the share
    function devolve() external {
        require(msg.sender == runningTontineAddress);

        emit Devolved(address(this).balance, now);

        selfdestruct(owner);
    }

    // Events
    event Locked(uint ts);
    event ReadyToCollect(uint ts, uint expiry);
    event Devolved(uint amount, uint ts);
    event Culled();
    event Cancelled();
}
