/*
 * Copyright © 2021 runtoken.io  ALL RIGHTS RESERVED.
 */

pragma solidity ^0.6.12;

import "./libs/IBEP20.sol";
import './libs/IPancakePair.sol';
import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract RUNToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = 'runtoken.io';
    string private _symbol = 'RUN';
    uint8 private _decimals = 18;

    uint256 private _lastBurn;
    address private _pair;
    uint256 private _totalSupply;

    uint public constant DAILY_BURN = 3; // percentage
    uint public constant DEX_BURNER = 10; // blocks
    uint private constant _INITAL_SUPPLY = 100 * 10**6 * 10**18;

    constructor() public {
        _lastBurn = block.number;

        _totalSupply = _totalSupply.add(_INITAL_SUPPLY);
        _balances[_msgSender()] = _INITAL_SUPPLY;

        emit Transfer(address(0), _msgSender(), _INITAL_SUPPLY);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "BEP20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);
    }

    function dexBurn() public {
        if(_pair != address(0) && _lastBurn.add(DEX_BURNER) <= block.number) {
            uint256 calculcateBurn = _balances[_pair].mul(DAILY_BURN).div(100);

            _burn(_pair, calculcateBurn);
            _lastBurn = block.number;

            _mint(_msgSender(), 250 * 10**18);

            IPancakePair pair = IPancakePair(_pair);
            pair.sync();
        }
    }

    function getLastBurn() public view returns(uint256) {
        return _lastBurn;
    }

    function getNextBurn() public view returns(uint256) {
        if(_lastBurn.add(DEX_BURNER) > block.number) {
            uint256 nextBurn = _lastBurn.add(DEX_BURNER).sub(block.number);
            return nextBurn;
        } else {
            return uint256(0);
        }
    }

    function isPair(address pair) public view onlyOwner returns(bool) {
        return pair == _pair;
    }

    function setPair(address pair) public onlyOwner {
        require(pair != address(0), "RUN: the pair is zero address");
        _pair = pair;
    }
}