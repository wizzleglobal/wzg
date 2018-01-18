pragma solidity ^0.4.18;

import "./WZGToken.sol";
import "./Ownable.sol";

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

    // TODO: Add call for claimTokens()

}
