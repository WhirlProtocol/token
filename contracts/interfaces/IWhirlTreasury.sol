// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWhirlTreasury {

    // state vars //
    ////////////////

    function excessTreasury() external view returns (uint256);
    function whirlDeployed() external view returns (uint256);
    function whirlPolFromRealign() external view returns (uint256);

    // helpers //
    /////////////

    function currentTunnelCost() external view returns(uint256);

    // getters //
    /////////////

    function totalBalance() external view returns (uint256);
    function isOversold() external view returns (bool);

    // setters //
    /////////////

    function setExcessTreasury(uint256 _excessTreasury) external returns (bool);
}
