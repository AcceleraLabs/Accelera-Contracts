// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title USDe
 * @notice USDe Genesis Story: Arthur Hayes' $Nakadollar in "Dust on Crust" 08/03/2023
 */
contract USDe is ERC20 {

  constructor(address admin) ERC20("USDe", "USDe") {}

}