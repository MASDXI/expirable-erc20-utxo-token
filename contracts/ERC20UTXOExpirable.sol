// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20UTXO.sol";

abstract contract ERC20UTXOExpirable is ERC20UTXO, Ownable {

    uint64 private immutable _period;

    constructor(uint64 period_) {
        _period = period_ ;
    }

    function mint(uint256 amount, TxOutput memory outputs) public onlyOwner { 
        _mint(amount, outputs, abi.encode(block.timestamp + _period));
    }

    function _beforeSpend(address spender, UTXO memory utxo) internal override {
        uint256 expireDate = abi.decode(utxo.data, (uint256));
        require(block.timestamp < expireDate,"UTXO has been expire");
    }
}