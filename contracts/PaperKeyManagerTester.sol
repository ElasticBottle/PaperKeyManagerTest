// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@paperxyz/contracts/keyManager/IPaperKeyManager.sol";

/// @custom:security-contact team@paper.xyz
contract PaperKeyManagerTest {
    IPaperKeyManager public paperKeyManager;
    event Registered();
    event Verified();

    constructor(address _paperKeyManagerAddress) {
        paperKeyManager = IPaperKeyManager(_paperKeyManagerAddress);
    }

    function registerPaperKey(address _paperKey) external returns (bool) {
        require(
            paperKeyManager.register(_paperKey),
            "Failed to register _paperKey"
        );
        emit Registered();
        return true;
    }

    function verifySignature(bytes32 _nonce, bytes calldata _signature)
        external
    {
        require(
            paperKeyManager.verify(
                keccak256(abi.encode(bytes32(""))),
                _nonce,
                _signature
            ),
            "Error Verifying signature"
        );
        emit Verified();
    }
}
