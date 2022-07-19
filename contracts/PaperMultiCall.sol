// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @custom:security-contact team@paper.xyz
contract PaperMultiCall is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] calldata _pauserAddresses,
        address[] calldata _upgraderAddresses,
        address[] calldata _withdrawAddresses,
        address[] calldata _callerAddresses
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // TODO: Maybe remvoe
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(WITHDRAW_ROLE, msg.sender);
        _grantRole(CALLER_ROLE, msg.sender);

        _setRoleAdmin(PAUSER_ROLE, PAUSER_ROLE);
        for (uint256 i = 0; i < _pauserAddresses.length; ++i) {
            _grantRole(PAUSER_ROLE, _pauserAddresses[i]);
        }

        _setRoleAdmin(PAUSER_ROLE, UPGRADER_ROLE);
        for (uint256 i = 0; i < _upgraderAddresses.length; ++i) {
            _grantRole(UPGRADER_ROLE, _upgraderAddresses[i]);
        }

        _setRoleAdmin(PAUSER_ROLE, WITHDRAW_ROLE);
        for (uint256 i = 0; i < _withdrawAddresses.length; ++i) {
            _grantRole(WITHDRAW_ROLE, _withdrawAddresses[i]);
        }

        _setRoleAdmin(PAUSER_ROLE, CALLER_ROLE);
        for (uint256 i = 0; i < _callerAddresses.length; ++i) {
            _grantRole(CALLER_ROLE, _callerAddresses[i]);
        }
    }

    /// @dev rough stub on withdrawing token from contract
    function withdrawTokens(
        address _tokenAddress,
        uint256 _amount,
        address _to
    ) external whenNotPaused returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(WITHDRAW_ROLE, msg.sender),
            "Not allowed"
        );
        bool success = IERC20Upgradeable(_tokenAddress).transfer(_to, _amount);
        require(success, "Error sending token to address");
        return true;
    }

    /// @dev execute trasnactions atomically
    function callSingleTransaction(
        address[] calldata _targets,
        bytes[] calldata _data
    ) external payable whenNotPaused returns (bytes[] memory result) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(CALLER_ROLE, msg.sender),
            "Not allowed"
        );

        require(_targets.length == _data.length, "Malformed inputs");
        require(_targets.length <= 2, "Too many contracts to call");

        result = new bytes[](_targets.length);
        // Only one transaction
        if (_targets.length == 1) {
            (bool success, bytes memory returnData) = _targets[0].call{
                value: msg.value
            }(_data[0]);
            require(success, "Execution Reverted");
            result[0] = returnData;
        } else {
            // two transaction
            for (uint256 i = 0; i < _targets.length; ++i) {
                (bool success, bytes memory returnData) = _targets[i].call{
                    value: msg.value
                }(_data[i]);
                require(success, "Execution Reverted");
                result[i] = returnData;
            }
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}

// Max player is 8
// When player join, Get their consent to buy in x amount of chips
// Once player confims, we lock up that amount of funds.
// If we successfully lock up funds, let player into the room
// Otherwise we kick the player out.
// After every round, reset the room.
// When player leaves unlock their funds
