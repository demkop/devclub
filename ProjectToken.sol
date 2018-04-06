pragma solidity ^0.4.21;

/* this is for development puproses to test and kill contract */
import "./mortal.sol";


import "./ERC20_Token.sol";
import "./ERC20_Details.sol";


contract ProjectToken is mortal, ERC20_Token, ERC20_Details {

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowance;

	uint256 public supply;
	
	function ProjectToken (uint256 _totalSupply, string _name, string _symbol, uint8 _decimals) 
		ERC20_Details(_name, _symbol, _decimals) public {
		supply = _totalSupply;
		balances[msg.sender] = _totalSupply;
	}

	function totalSupply() public constant returns(uint256 _totalSupply) {
		return supply;
	}

	function balanceOf(address addr) public constant returns(uint256 balance) {
		return balances[addr];
	}

	 function transfer(address _to, uint256 _value) public No0x(_to) ValidBalance(msg.sender, _to, _value) 
	 returns (bool success) {                        
        balances[msg.sender] -= _value;                      // Subtract from the sender
        balances[_to] += _value;                             // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);              // Notify anyone listening that this transfer took place
    	return true;
    }

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowance[_owner][_spender];	
	}

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }  

    function transferFrom(address _from, address _to, uint256 _value) public No0x(_to) No0x(_from) ValidBalance(_from, _to, _value) returns (bool success) {
    	require (_value <= allowance[_from][msg.sender]);     // Check allowance
        balances[_from] -= _value;                               // Subtract from the sender
        balances[_to] += _value;                                 // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

	function name() public view returns (string _name) {
		return tokenName;
	}

	function symbol() public view returns (string _symbol) {
		return tokenSymbol;
	}

	function decimals() public view returns (uint8 _decimals) {
		return tokenDecimals;
	}

	// Prevent an account from behing 0x0
	modifier No0x(address addr) { 
		require (addr != 0x0);
		_; 
	}

	// A modifer to check validity of a balance for a transfer
	modifier ValidBalance(address from, address to, uint256 value) { 
		require (value <= balances[from]);                 // Check if the sender has enough
		require (balances[to] + value > balances[to]);    // Check for overflows
		_; 
	}
}
