pragma solidity ^0.4.18;

import "./WZGToken.sol";
import "./Ownable.sol";
import "./ERC20Basic.sol";

contract WizzleGlobalController is Ownable {

    // block number when controller was created
    uint public creationBlock;
    WizzleGlobalToken public token;

    function WizzleGlobalController(address _tokenAddress) public {
        token = WizzleGlobalToken(_tokenAddress);
        creationBlock = block.number;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public onlyOwner returns (bool) {
        return token.transferFrom(_from, _to, _amount);
    }

    function mint(address _owner, uint _amount) public onlyOwner returns (bool) {
        return token.mint(_owner, _amount);
    }

    function enableTransfers(bool _transfersEnabled) public onlyOwner {
        token.enableTransfers(_transfersEnabled);
    }

    function claimTokens(address _token) public {
        token.claimTokens(_token);
    }

    function transferAnyERC20Token(address tokenAddress, uint _amount) public onlyOwner returns (bool success) {
        return ERC20Basic(tokenAddress).transfer(owner, _amount);
    }

    function transferEther(address destination) public onlyOwner {
        destination.transfer(this.balance);
    }

}
