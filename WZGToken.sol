pragma solidity ^0.4.18;

import "./Controlled.sol";
//import "./TokenController.sol";

contract WizzleGlobalToken is Controlled {

    string public name;              
    uint8 public decimals;            
    string public symbol;

    struct Checkpoint {
        uint128 fromBlock;
        uint128 value;
    }

    // block number when token was created
    uint public creationBlock;
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

    function doTransfer(address _from, address _to, uint _amount) internal {
           if (_amount == 0) {
               Transfer(_from, _to, _amount); // follow the spec to raise the event when transfer 0
               return;
           }

           require((_to != address(0)) && (_to != address(this)));
           var previousBalanceFrom = balanceOf(_from);
           require(previousBalanceFrom >= _amount);
           var previousBalanceTo = balanceOf(_to);
           require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow

           // Alerts the token controller of the transfer
           /*
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }
           */

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

        // Alerts the token controller of the approve function call
        /*
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }
        */

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

    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

    function mint(address _owner, uint _amount) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }

    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0) 
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) 
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length-1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
               newCheckPoint.fromBlock = uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    /*
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) 
            return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }
    */

    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    /*
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }
    */

    function () public payable {
        revert();
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    /*
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance); // TODO: Maybe not needed if fallback calls revert()
            return;
        }

        WizzleGlobalToken token = WizzleGlobalToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }
    */

}
