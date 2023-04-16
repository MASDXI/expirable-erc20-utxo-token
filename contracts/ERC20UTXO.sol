// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IERC20UTXO.sol";

contract ERC20UTXO is Context, IERC20UTXO {
    using ECDSA for bytes32;
    
    UTXO[] private _utxos;

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory){
        return _name;
    }

    function symbol() public view virtual override returns (string memory){
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8){
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function utxoLength() public view returns (uint256) {
        return _utxos.length;
    }

    function utxo(uint256 id) public override view returns (UTXO memory) {
        require(id < _utxos.length, "ERC20UTXO: id out of bound");
        return _utxos[id];
    }

    function transfer(uint256 amount, TxInput memory input, TxOutput memory output) public virtual {
        require(output.amount <= amount, "ERC20UTXO: transfer amount exceeds utxo amount");
        address creator = _msgSender();
        bytes storage data = _utxos[input.id].data;
        if (output.amount < amount) {
            uint256 value = amount - output.amount;
            _spend(input, creator);
            unchecked {
                _balances[creator] -= value;   
                _balances[output.owner] += amount;
            }
            _create(output, creator, data);
            _create(TxOutput(value, creator), creator, data);
        } else {
            _spend(input,creator);
            unchecked {
                _balances[creator] -= amount;   
                _balances[output.owner] += amount;
            }
            _create(output, creator, data);
        }
    }

    function _mint(uint256 amount, TxOutput memory output, bytes memory data) internal virtual {
        require(output.amount == amount, "ERC20UTXO: invalid amounts");
        _totalSupply += amount;
        unchecked {
            _balances[output.owner] += amount;
        }
        _create(output, address(0), data);
    }
    
    function _create(TxOutput memory output, address creator, bytes memory data) internal virtual {
        require(output.owner != address(0),"ERC20UTXO: create utxo output to zero address");
        uint256 id = utxoLength()+1;
        UTXO memory utxo = UTXO(output.amount, output.owner, data, false);
        
        _beforeCreate(output.owner,utxo);

        _utxos.push(utxo);
        emit UTXOCreated(id, creator);

        _afterCreate(output.owner,utxo);
    }

    function _spend(TxInput memory inputs, address spender) internal virtual {
        require(inputs.id < _utxos.length, "ERC20UTXO: utxo id out of bound");
        UTXO memory utxo = _utxos[inputs.id];
        require(!utxo.spent, "ERC20UTXO: utxo has been spent");

        _beforeSpend(utxo.owner,utxo);

        require(
            utxo.owner == keccak256(abi.encodePacked(inputs.id))
                          .toEthSignedMessageHash()
                          .recover(inputs.signature),
                          "ERC20UTXO: invalid signature");
        _utxos[inputs.id].spent = true;
        emit UTXOSpent(inputs.id, spender);

        _afterSpend(utxo.owner,utxo);
    }

    function _beforeCreate(address creator, UTXO memory utxo) internal virtual {}

    function _afterCreate(address creator, UTXO memory utxo) internal virtual {}

    function _beforeSpend(address spender, UTXO memory utxo) internal virtual {}

    function _afterSpend(address spender, UTXO memory utxo) internal virtual {}
    
}