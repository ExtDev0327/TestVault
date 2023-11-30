// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "@libraries/Errors.sol";

contract Vault is Ownable{

    
    // Events

    /// @notice Emitted when a user deposit assets
    /// @param user Address of the user
    /// @param token Address of the token
    /// @param amount Amount of the token
    event TokenDeposited(address user, address token, uint256 amount);

    /// @notice Emitted when a user withdraw assets
    /// @param user Address of the user
    /// @param token Address of the token
    /// @param amount Amount of the token
    event TokenWithdrawn(address user, address token, uint256 amount);
    
    /// @notice Emitted when a token is registered.
    /// @param token Address of the registered token 
    event TokenWhitelisted(address token);

    /// @notice Emitted when the vault is paused.
    event Paused();

    /// @notice Emitted when the vault is resumed.
    event Resumed();

    // Types

    using SafeERC20 for IERC20;

    // Immutables
    
    /// @dev flag for running or not
    bool internal constant PAUSED = false;
    bool internal constant RUNNING = true;

    // Storage
    
    /// @dev Vault's status. Can be PAUSED or RUNNING
    bool public status;

    /// @notice whitelist of tokens
    /// @dev indexed by token address
    mapping (address token => bool allowed) public isWhitelisted;

    /// @notice Token balances for each user
    /// @dev indexed by user, then by token address
    mapping (address user => mapping(address token => uint256 amount)) public balances;

    
    modifier onlyWhitelisted(address token) {
        if (!isWhitelisted[token]) revert Errors.UnauthorizedToken();
        _;
    }

    modifier isRunning() {
        if (status != RUNNING) revert Errors.ActionWhenPaused();
        _;
    }

    constructor() Ownable(msg.sender) {
        status = RUNNING;
    }

    /// @notice deposit erc20 assets
    /// @dev revert if the vault is pasued
    /// @dev revert if token is not whitelisted
    /// @param token Address of erc20
    /// @param amount Amount of token to be deposited
    function deposit(address token, uint256 amount) isRunning onlyWhitelisted(token)  external {
        balances[msg.sender][token] += amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit TokenDeposited(msg.sender, token, amount);
    }

    /// @notice withdraw erc20 assets from the vault
    /// @dev revert if the vault is pasued
    /// @dev revert if token is not whitelisted
    /// @param token Address of erc20
    /// @param amount Amount of token to be withdrawn
    function withdraw(address token, uint256 amount) isRunning onlyWhitelisted(token) external {
        if (balances[msg.sender][token] < amount) {
            revert Errors.NotEnoughBalance(msg.sender, token, amount);
        }

        unchecked {
            balances[msg.sender][token] -= amount;            
        }

        IERC20(token).safeTransfer(msg.sender, amount);

        emit TokenWithdrawn(msg.sender, token, amount);
    }

    /// @notice whitelist a token
    /// @dev the only admin can whitelist a token
    /// @dev revert if the token has already been whitelisted
    /// @param token Address of token to be whitelisted

    function registerToken(address token) onlyOwner external {
        if (isWhitelisted[token]) revert Errors.AlreadyRegistered();

        isWhitelisted[token] = true;

        emit TokenWhitelisted(token);
    }

    /// @notice pause a vault
    /// @dev the only admin can pause the vault
    /// @dev revert if the vault has already been paused
    function pause() onlyOwner external {
        if (status == PAUSED) revert Errors.AlreadyPaused();

        status = PAUSED;

        emit Paused();
    }

    /// @notice resume a vault
    /// @dev the only admin can resume the vault
    /// @dev revert if the vault is running
    function unpause() onlyOwner external {
        if (status != PAUSED) revert Errors.AlreadyRunning();

        status = RUNNING;

        emit Resumed();
    }
}