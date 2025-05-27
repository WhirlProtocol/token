// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWhirlTreasury.sol";

// a message to devs scoping this contract in future, especially newer devs..
// alot of crypto is fucking nonsense nowadays honestly. you can be part of the cohort of devs bringing new ideas into the space and 
// pushing the tech forwards, or you can be in the cohort of "devs" mass-vomiting tokens into the market who's only differentiator is their ticker. 
// choose wisely because every day you spend learning to deploy shitcoins is a day you could have been honing actual skills and applying them to novel ideas. 
// build something challenging and that you think can make a splash, and have fun doing it. don't just get caught up in the money side of it, embrace the tech itself.
// with love and positive hopes for your work, v 

contract Whirl is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // state vars //
    ////////////////

    address public treasury;
    address public genesisPool;
    address public genesisPoolFeesAddr;
    bool public buyRestrictionMaster; // turn buy restrictions on and off
    bool public onlyTreasuryBuys; // set prior to clearExcess in treasury to protect it
    EnumerableSet.AddressSet private _minters;

    // mappings //
    //////////////

    mapping(uint8 => bool) public killSwitches; // Kill switches for setters

    // modifiers //
    ///////////////

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Whirl: not minter");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "!0");
        _;
    }

    modifier notKilled(uint8 functionId) {
        require(!killSwitches[functionId], "Setter has been disabled");
        _;
    }

    // events //
    ////////////

    event KillSwitchesUpdated(bool[] switches);

    // errors //
    ////////////

    error UnauthorizedTransfer(address sender, address recipient);

    // constructor //
    /////////////////

    constructor() ERC20("Whirl", "WHIRL") Ownable(msg.sender) {}

    // mint and burn //
    ///////////////////

    function mint(address _to, uint256 _amount) external onlyMinter returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) external onlyOwner notKilled(0) {
        _burn(_account, _amount);
    }

    function getMinter(uint256 _index) external view returns (address) {
        require(_index <= getMinterLength() - 1, "Whirl: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address _account) public view returns (bool) {
        return EnumerableSet.contains(_minters, _account);
    }

    // sandwich protection //
    /////////////////////////

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (buyRestrictionMaster) { // stacked conditionals to minimise gas in as many cases as possible
            if (msg.sender == genesisPool && recipient != genesisPool && recipient != genesisPoolFeesAddr) { // buy swaps only are prevented
                if (onlyTreasuryBuys || IWhirlTreasury(treasury).isOversold()) { // either manually set for clearExcess, or oversold state
                    require(recipient == treasury, "Whirl: Only treasury can buy from Genesis pool"); // if all are truthy, only allow treasury to buy
                }
            } 
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (buyRestrictionMaster) { // stacked conditionals to minimise gas in as many cases as possible
            if (msg.sender == genesisPool && recipient != genesisPool && recipient != genesisPoolFeesAddr) { // buy swaps only are prevented
                if (onlyTreasuryBuys || IWhirlTreasury(treasury).isOversold()) { // either manually set for clearExcess, or oversold state
                    require(recipient == treasury, "Whirl: Only treasury can buy from Genesis pool"); // if all are truthy, only allow treasury to buy
                }
            }
        }
        return super.transferFrom(sender, recipient, amount);
    }

    // setters //
    /////////////

    function addMinter(
        address _addMinter
    ) public onlyOwner onlyValidAddress(_addMinter) notKilled(1) returns (bool) {
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(
        address _delMinter
    ) external onlyOwner onlyValidAddress(_delMinter) notKilled(2) returns (bool) {
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function setBuyRestrictionMaster(bool _isEnabled) public onlyOwner notKilled(3) {
        buyRestrictionMaster = _isEnabled;
    }

    function setOnlyTreasuryBuys(bool _isEnabled) public onlyOwner notKilled(4) {
        onlyTreasuryBuys = _isEnabled;
    }

    function setTreasury(address _treasury) public onlyOwner onlyValidAddress(_treasury) notKilled(5) {
        treasury = _treasury;
    }

    function setPool(address _pool) public onlyOwner onlyValidAddress(_pool) notKilled(6) {
        genesisPool = _pool;
    }

    function setPoolFeesAddr(address _poolFeesAddr) public onlyOwner onlyValidAddress(_poolFeesAddr) notKilled(7) {
        genesisPoolFeesAddr = _poolFeesAddr;
    }

    function initializeWhirl(address _whirlMine, address _treasury) external {
        addMinter(_whirlMine);
        setTreasury(_treasury);
    }

    function initializePool(address _pool, address _poolFeesAddr, bool _buyerRestriction) external {
        setPool(_pool);
        setPoolFeesAddr(_poolFeesAddr);
        setBuyRestrictionMaster(_buyerRestriction);
    }

    function setKillSwitches(bool[] calldata switches) external onlyOwner notKilled(8) {
        require(switches.length == 9, "L!"); 
        for(uint8 i = 0; i < switches.length; i++) {
            killSwitches[i] = switches[i];
        }
        emit KillSwitchesUpdated(switches);
    } // kill switches used post launch but pre-significant activity.  allows for live iterations in alignment with users if needed.  easily checkible for reassurance. #
}
