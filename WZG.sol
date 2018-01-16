pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20 {

  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

}

// TODO: basic implementation
// We still have to add balanceAt (like in MiniMeToken)
// This Token will be controled by controller (this has not been implemented)
contract StandardToken is ERC20, Ownable {

  using SafeMath for uint;

  bool public pauseTransfer = false;
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) internal allowed;

  event Mint(address to, uint amount);
  event Pause();
  event Unpause();

  
  // Don't accept ETH
  function () public payable {
    revert();
  }  

  function pause() public onlyOwner {
      pauseTransfer = true;
      Pause();
  }

  function unpause() public onlyOwner {
      pauseTransfer = false;
      Unpause();
  }

    function mint(address _to, uint _amount) public onlyOwner returns (bool) {
      require(_to != address(0));
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      Mint(_to, _amount);
      return true;
  } 

 function _transfer(address _from, address _to, uint _value) internal {
    require(_to != address(0));
    require(balances[_to].add(_value) >= balances[_to]);    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
  
  function transfer(address _to, uint _value) public returns (bool) {
    require(!pauseTransfer);
    _transfer(msg.sender, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  
  // Owner can transfer out any accidentally sent ERC20 tokens
  function transferAnyERC20Token(address tokenAddress, uint _amount) public onlyOwner returns (bool success) {
      return ERC20(tokenAddress).transfer(owner, _amount);
  }

}

contract WizzleGlobalToken is StandardToken {
    string public constant name = "Wizzle Global Token";
    string public constant symbol = "WZG";
    uint8 public constant decimals = 0;
    function WizzleGlobalToken() public { 
        totalSupply = 0;
    }
}