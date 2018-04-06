pragma solidity ^0.4.21;

/* this is for development puproses to test and kill contract */
import "./mortal.sol";
import "./ERC20_Token.sol";
import "./SafeMath.sol";

contract DevEx is mortal, SafeMath {

  address public admin; //the admin address

  mapping (address => mapping (address => uint256)) public tokens;
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint256)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

  event Order(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user);
  event Cancel(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user);
  event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address get, address give);
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);


  function DevEx() public {
    admin = msg.sender;
  }

  function() public {
    revert();
  }

  function promoteToAdmin(address _admin) public adminOnly() {
    admin = _admin;
  }

  function deposit(address token, uint256 amount) public No0x(token) {
    ERC20_Token(token).transferFrom(msg.sender, this, amount);
    tokens[token][msg.sender] = add(tokens[token][msg.sender], amount);
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  // should it be allowed too? This needs to be tested!!!
  function withdraw(address token, uint256 amount) public No0x(token) {
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = subtract(tokens[token][msg.sender], amount);
    ERC20_Token(token).transfer(msg.sender, amount);
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) public constant No0x(token) returns (uint256) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce) public {

    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (orders[msg.sender][hash] == false) {
      orders[msg.sender][hash] = true;
      emit Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    }
  }

  // amount is in amountGet terms
  function trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint256 amount) public No0x(tokenGet) No0x(tokenGive) No0x(user) {
    if (testTrade(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, msg.sender, amount) == true) {
      tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);

      bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
      orderFills[user][hash] = add(orderFills[user][hash], amount);
      emit Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
    }
  }

  function tradeBalances(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address user, uint256 amount) private {
    tokens[tokenGet][msg.sender] = subtract(tokens[tokenGet][msg.sender], amount);
    tokens[tokenGet][user] = add(tokens[tokenGet][user], amount);
    tokens[tokenGive][user] = subtract(tokens[tokenGive][user], multiply(amountGive, amount) / amountGet);
    tokens[tokenGive][msg.sender] = add(tokens[tokenGive][msg.sender], multiply(amountGive, amount) / amountGet);
  }

  function testTrade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, address sender, uint256 amount) public constant No0x(tokenGet) returns(bool) {
    if (tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user) >= amount
    ) return true;
    return false;
  }

  function availableVolume(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user) public constant No0x(tokenGive) returns(uint256) {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(orders[user][hash] && block.number <= expires)) {
      return 0;
    }
    return min(subtract(amountGet, orderFills[user][hash]), multiply(tokens[tokenGive][user], amountGet) / amountGive);
  }

  function orderFill(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user) public constant No0x(user) returns(uint256) {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    return orderFills[user][hash];
  }

  function cancelOrder(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce) public {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(orders[msg.sender][hash])) {
      revert();
    }
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
  }

  function min(uint256 a, uint256 b) private pure returns (uint256) {
    if (a < b) {
      return a;
    }
    return b;
  }

  //Works on owner's command
  modifier adminOnly(){
    require (msg.sender == admin);
    _;
  }

  // Prevent an account from behing 0x0
  modifier No0x(address addr) { 
    require (addr != 0x0);
    _; 
  }
}