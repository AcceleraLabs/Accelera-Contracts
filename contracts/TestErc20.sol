// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestErc20 is ERC20 {

    constructor(   string memory name_, string memory symbol_, uint256 amount_) ERC20(name_, symbol_) {
        _mint(_msgSender(), amount_);
    }

}