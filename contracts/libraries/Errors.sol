// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title Custom Errors library.
/// @author ASaito
library Errors {
    /// Errors are alphabetically ordered

    /// @notice Action can't be run when vault has been paused
    error ActionWhenPaused();

    /// @notice Vault has already been running
    error AlreadyRunning();

    /// @notice Vault has already been paused
    error AlreadyPaused();

    /// @notice Token has already been registered
    error AlreadyRegistered();

    /// @notice User's balance isn't enough
    error NotEnoughBalance(address user, address token, uint256 amount);

    /// @notice Token hasn't been registered
    error UnauthorizedToken();
}
