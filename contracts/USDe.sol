// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title USDe
 * @notice USDe placeholder contract used just for testing and development puposes.
 */
contract USDe is ERC20 {

  constructor(address admin) ERC20("USDe", "USDe") {}

}