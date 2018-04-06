pragma solidity ^0.4.21;

/* this is for development puproses to test and kill contract */
contract mortal {
    
    address owner;

    function mortal() public { 
        owner = msg.sender; 
    }

    function kill() public { 
        if (msg.sender == owner) {
            selfdestruct(owner); 
        }
    }
}