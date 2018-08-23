pragma solidity ^0.4.21;

import "./lib.sol";
import "./runningtontine.sol";
import "./participant.sol";

contract Tontine {

    // Parameters of the tontine - implicitly agreed upon by participants choosing to invest
    // TODO: does this need to be a struct?
    TontineLib.DeviceParameters parameters;

    // Iterable list of addresses of all participants
    address[] public participants;

    // Participant count to allow traversal
    uint numParticipants;

    // Sum invested per participant
    mapping ( address => uint256 ) participantSumInvested;

    // Total amount invested in tontine
    uint256 totalSumInvested;

    constructor(uint _launchTs, uint _dividendPercent, address _investmentTarget) public {
        parameters = TontineLib.DeviceParameters({
            launchTs: _launchTs,
            dividendPercent: _dividendPercent,
            investmentTarget: _investmentTarget
        });

        numParticipants = 0;
    }

    // Invest a sum of money in the tontine
    function invest() payable external {
        require(msg.value > 0);

        if (participantSumInvested[msg.sender] == 0) {
            // New participant
            participants.push(msg.sender);
            numParticipants++;

            participantSumInvested[msg.sender] = msg.value;
        } else {
            // Existing participant that is investing more
            participantSumInvested[msg.sender] += msg.value;
        }

        totalSumInvested += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // Cancel the investment, returning the funds invested to the investor
    function cancelInvestment() external {
        require(participantSumInvested[msg.sender] > 0);

        msg.sender.transfer(participantSumInvested[msg.sender]);

        totalSumInvested -= participantSumInvested[msg.sender];
        participantSumInvested[msg.sender] = 0;
        numParticipants--;

        // Note that the participant will still exist in the array - save computation by not traversing to remove
        // Use the participantSumInvested value to determine if they still have money invested in the contract

        delete participantSumInvested[msg.sender];
    }

    // Lock up the invested funds, notify participants, calculate final shares and launch the tontine
    function launch() internal {
        RunningTontine runningTontine = new RunningTontine(parameters.investmentTarget);

        for (uint i = 0; i < numParticipants; i++) {

            // Ensure the participant has at least something invested
            if (participantSumInvested[participants[i]] > 0) {
                // Bear in mind that participants may appear twice as they are not removed from the array
                // Not an issue now as their share is not double calculated - but take care in the future

                uint256 share = (totalSumInvested * TontineLib.getFixedPointConstant()) /
                    (participantSumInvested[participants[i]] * TontineLib.getFixedPointConstant());

                // Inform the participant that their share has been locked, and the address of the running tontine
                Participant(participants[i]).lock(address(runningTontine));
                // Add the participant and their share to the running tontine
                runningTontine.addParticipant(participants[i], share);
            } else {
                // Participant is no longer needed and can be killed
                Participant(participants[i]).cull();
            }
        }

        emit Launch();

        selfdestruct(runningTontine);
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