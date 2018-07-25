pragma solidity ^0.4.21;

import "./lib.sol";
import "./runningtontine.sol";

// TODO: is mortal?
contract Tontine {

    // Parameters of the tontine - implicitly agreed upon by participants choosing to invest
    // TODO: does this need to be a struct?
    TontineStructs.DeviceParameters parameters;
    // List of all participants
    mapping ( address => TontineStructs.Participant ) participants;

    constructor(uint _launchTs, uint _dividendPercent, address _investmentTarget) public {
        parameters = TontineStructs.DeviceParameters({
            launchTs: _launchTs,
            dividendPercent: _dividendPercent,
            investmentTarget: _investmentTarget
        });
    }

    // Invest a sum of money in the tontine
    function invest() payable external {
        require(msg.value > 0);

        if (participants[msg.sender].exists) {
            participants[msg.sender].invested += msg.value;
        } else {
            participants[msg.sender] = TontineStructs.Participant({
                addr: msg.sender,
                invested: msg.value,
                exists: true });
        }

        emit Deposit(msg.sender, msg.value);
    }

    // Cancel the investment, returning the funds invested to the investor
    function cancelInvestment() external {
        require(participants[msg.sender].exists);

        participants[msg.sender].addr.transfer(participants[msg.sender].invested);

        delete participants[msg.sender];
    }

    // Lock up the funds and launch the tontine
    function launch() internal {
        address runAddr = new RunningTontine(parameters.investmentTarget);

        // TODO: calculate share here and notify participants
        // participant.lock()

        selfdestruct(runAddr);
    }

    // Getters
    function getLaunchTs() view external returns (uint) {
        return parameters.launchTs;
    }

    function getDividendPercent() view external returns (uint) {
        return parameters.dividendPercent;
    }

    function getInvestmentTarget() view external returns (address) {
        return parameters.investmentTarget;
    }

    // Events
    event Deposit(address _from, uint _amount);
    event Launch();
}