pragma solidity ^0.4.0;

// TODO: build a contract for verifying identity
contract identity {

    mapping

    // Private address of identity manager
    address identityManager;

    constructor() public {
        identityManager = msg.sender;
    }
}
