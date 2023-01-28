// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20_staking is ERC20, ERC20Burnable, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => bool) controllers;

  uint256 private _totalSupply;
  uint256 private max_Supply;
  uint256 constant max_Supply_Token = 5000000000000000000;

  constructor() ERC20("Gomz Staking Token", "GST") { 
      _mint(msg.sender, 1000000000000000);

  }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require((max_Supply+amount)<=max_Supply_Token,"Maximum supply has been reached");
    _totalSupply = _totalSupply.add(amount);
    max_Supply=max_Supply.add(amount);
    _balances[to] = _balances[to].add(amount);
    _mint(to, amount);
  }

  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
  
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function max_Supplyply() public  pure returns (uint256) {
    return max_Supply_Token;
  }

}