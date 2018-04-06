pragma solidity ^0.4.21;

contract SafeMath {

  function multiply(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function subtract(uint256 a, uint256 b) public pure returns (uint256) {
    require (b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}