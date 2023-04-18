// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IERC20UTXO {

    struct UTXO {
        uint256 amount;
        address owner;
        bytes data;
        bool spent;
    }

    struct TxInput {
        uint256 id;
        bytes signature;
    }

    struct TxOutput {
        uint256 amount;
        address owner;
    }

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
    
    function utxo(uint256 id) external view returns (UTXO memory);

    function utxoLength() external view returns (uint256);

    function transfer(uint256 amount, TxInput memory input, TxOutput memory output) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event UTXOCreated(uint256 indexed id, address indexed creator);

    event UTXOSpent(uint256 indexed id, address indexed spender);

    event Approval(address indexed owner, address indexed spender, uint256 id, uint256 value);

}
