pragma solidity ^0.4.21;

contract ERC20_Details {
	
	//fancy name: eg Simon Bucks
	string tokenName;       
	//An identifier: eg SBX
    string tokenSymbol;     
    //How many decimals to show.
	uint8  tokenDecimals;   

	function name() public view returns (string _name);
	function symbol() public view returns (string _symbol);
	function decimals() public view returns (uint8 _decimals);

	function ERC20_Details(string _name, string _symbol, uint8 _decimals) public {
		require (keccak256(_name) != keccak256(''));
		require (keccak256(_symbol) != keccak256(''));

		tokenName = _name;
		tokenSymbol = _symbol;
		tokenDecimals = _decimals;
	}

}
