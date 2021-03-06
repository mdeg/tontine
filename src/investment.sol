pragma solidity ^0.4.21;

// This contract should be run
// TODO: this requires trust - is there a trustless on-chain way to invest?
contract Investment {

    // The address of the originating tontine
    address tontineAddress;
    // The timestamp the investment started at
    uint startTs;
    // The percent of return on investment to pay out as dividends
    uint dividendPercent;

    // TODO: investment period

    constructor(uint _dividendPercent) public {
        dividendPercent = _dividendPercent;

        tontineAddress = msg.sender;
        startTs = now;
    }

    // Return a percent of the investment as dividends
    function returnInvestment() {
        // TODO: compare to previous invested value and only return the dividend if we have made a return on investment
        tontineAddress.transfer(address(this).balance * dividendPercent);
    }

    // The running tontine has wrapped up, so this contract can die and return anything left
    function end() {
        selfdestruct(tontineAddress);
    }
}