pragma solidity ^0.4.18;

import "./Controlled.sol";
import "./ERC20Basic.sol";

contract WizzleGlobalToken is Controlled {

    string public name;              
    uint8 public decimals;            
    string public symbol;

    struct Checkpoint {
        uint128 fromBlock;
        uint128 value;
    }

    // block number when token was created
    uint256 public creationBlock;
    mapping (address => Checkpoint[]) balances;
    mapping (address => mapping (address => uint256)) allowed;
    Checkpoint[] totalSupplyHistory;
    bool public transfersEnabled;
    
    function WizzleGlobalToken() public {
        name = "Wizzle Global Token";           
        decimals = 0;         
        symbol = "WZG";                 
        transfersEnabled = false;
        creationBlock = block.number;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (msg.sender != controller) {
            require(transfersEnabled);
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        // controller can always do transfers
        doTransfer(_from, _to, _amount);
        return true;
    }

    function doTransfer(address _from, address _to, uint256 _amount) internal {
           if (_amount == 0) {
               Transfer(_from, _to, _amount); // follow the spec to raise the event when transfer 0
               return;
           }

           require((_to != address(0)) && (_to != address(this)));
           var previousBalanceFrom = balanceOf(_from);
           require(previousBalanceFrom >= _amount);
           var previousBalanceTo = balanceOf(_to);
           require(previousBalanceTo + _amount >= previousBalanceTo); // overflow

           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);
           Transfer(_from, _to, _amount);
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }

    function balanceOfAt(address _owner, uint256 _blockNumber) public constant returns (uint256) {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    function totalSupplyAt(uint256 _blockNumber) public constant returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

    function mint(address _owner, uint256 _amount) public onlyController returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // overflow
        uint256 previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }

    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block) constant internal returns (uint256) {
        if (checkpoints.length == 0) 
            return 0;

        // shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) 
            return 0;

        // binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length-1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
               newCheckPoint.fromBlock = uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    function min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a < b ? a : b;
    }

    function () public payable {
        revert();
    }

    function claimTokens(address _token) public onlyController {
        if (_token == address(0)) {
            // even if fallback calls revert(), there could be balance
            controller.transfer(this.balance); 
            return;
        }

        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint256 _snapshotBlock);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

}
