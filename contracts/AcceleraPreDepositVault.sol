// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract AcceleraPreDepositVault is ERC4626, Ownable {
    bool public depositsEnabled;
    bool public withdrawalsEnabled;
    bool public referralCodeCreationEnabled;
    bool public referralCodeMandatory;
    bool public useReferralOnlyInDeposits;
    uint public minimumBalanceToGenerateCode;

    uint private counter;

    mapping(string => address) public referralCodeToOwner;
    mapping(address => string) public ownerToReferralCode;
    mapping(address => string) private addressToCodeUsed;


    error DepositsDisabled();
    error WithdrawalsDisabled();
    error ReferralCodeCreationDisabled();
    error ReferralCodeMandatory();
    error ReferralCodeDoesNotExist();
    error ReferralCodeAlreadyUsed();
    error AddressAlreadyHasReferralCode();
    error NotEnoughXUSDEToGenerateCode();
    error CantReferYourself();

    event DepositsEnabled(bool enabled);
    event WithdrawalsEnabled(bool enabled);
    event ReferralCodeCreationEnabled(bool enabled);
    event ReferralCodeMandatoryEnabled(bool enabled);
    event UseReferralOnlyInDepositsEnabled( bool enable );
    event SetMinimumBalanceToGenerateCode( uint minimum );

    event ReferralCodeCreated( address user, string code );
    event ReferralCodeVIP( address user, string code, bool isVip );
    event ReferralCodeUsed( address user, string code );

    constructor(address initialOwner_, IERC20 asset_, string memory name_, string memory symbol_)
        ERC4626(asset_)
        ERC20(name_, symbol_)
        Ownable(initialOwner_)
    {
        depositsEnabled = true;
        withdrawalsEnabled = true;
        referralCodeMandatory = false;
        referralCodeCreationEnabled = true;
        useReferralOnlyInDeposits = true;
        minimumBalanceToGenerateCode = 1000*10**18;
    }

    function depositWithReferral(uint256 assets, address receiver, string memory code_) public returns (uint256) {

        useReferralCode ( _msgSender(), code_);

        uint256 shares = deposit(assets, receiver);

        return shares;
    }

    function createReferralCode() external {
        if (!referralCodeCreationEnabled) revert ReferralCodeCreationDisabled();

        if ( balanceOf(_msgSender()) < minimumBalanceToGenerateCode ) revert NotEnoughXUSDEToGenerateCode();

        address user_ = _msgSender();
        string memory code_ = randomString(6);

        if( referralCodeToOwner[code_] != address(0) ) revert ReferralCodeAlreadyUsed();
        
        if ( bytes(ownerToReferralCode[user_]).length != 0 ) revert AddressAlreadyHasReferralCode();
        
        referralCodeToOwner[code_] = user_;
        ownerToReferralCode[user_] = code_;

        emit ReferralCodeCreated(user_, code_);
    }

    function useReferralCode(string memory code_) public {
        if (useReferralOnlyInDeposits) revert ReferralCodeCreationDisabled();

        useReferralCode ( _msgSender(), code_);
    }

    /* OVERRIDEN FUNCTIONS */

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        
        if (!depositsEnabled) {
            revert DepositsDisabled();
        }

        super._deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (!withdrawalsEnabled) {
            revert WithdrawalsDisabled();
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (referralCodeMandatory && bytes(addressToCodeUsed[to]).length == 0) {
            revert ReferralCodeMandatory();
        }
        super._update( from, to, value);
    }

    /* OWNER FUNCTIONS */

    function createReferralCodeOwner( address user_, string memory code_ ) external onlyOwner {

        if ( bytes(code_).length == 0 ) code_ = randomString(6);

        if( referralCodeToOwner[code_] != address(0) ) revert ReferralCodeAlreadyUsed();
        
        if ( bytes(ownerToReferralCode[user_]).length != 0 ) revert AddressAlreadyHasReferralCode();
        
        referralCodeToOwner[code_] = user_;
        ownerToReferralCode[user_] = code_;

        emit ReferralCodeCreated(user_, code_);
    }

    function setVipReferral(string memory code_, bool isVip_) external onlyOwner {
        address user_ = referralCodeToOwner[code_];
        // only for indexing purposes
        emit ReferralCodeVIP(user_, code_, isVip_);
    }

    function setDepositsEnabled(bool depositsEnabled_) external onlyOwner {
        depositsEnabled = depositsEnabled_;
        emit DepositsEnabled(depositsEnabled_);
    }

    function setWithdrawalsEnabled(bool withdrawalsEnabled_) external onlyOwner {
        withdrawalsEnabled = withdrawalsEnabled_;
        emit WithdrawalsEnabled(withdrawalsEnabled_);
    }

    function setReferralCodeCreationEnabled(bool referralCodeCreationEnabled_) external onlyOwner {
        referralCodeCreationEnabled = referralCodeCreationEnabled_;
        emit ReferralCodeCreationEnabled(referralCodeCreationEnabled_);
    }

    function setReferralCodeMandatory(bool referralCodeMandatory_) external onlyOwner {
        referralCodeMandatory = referralCodeMandatory_;
        emit ReferralCodeMandatoryEnabled(referralCodeMandatory_);
    }

    function setUseReferralOnlyInDeposits ( bool useReferralOnlyInDeposits_ ) external onlyOwner {
        useReferralOnlyInDeposits = useReferralOnlyInDeposits_;
        emit UseReferralOnlyInDepositsEnabled(useReferralOnlyInDeposits_);
    }

    function setMinimumBalanceToGenerateCode ( uint minimumBalanceToGenerateCode_ ) external onlyOwner {
        minimumBalanceToGenerateCode = minimumBalanceToGenerateCode_;
        emit SetMinimumBalanceToGenerateCode(minimumBalanceToGenerateCode_);
    }

    /* INTERNAL FUNCTIONS */

    function useReferralCode ( address user, string memory code_) internal {
        if ( bytes(code_).length != 0 ) {
            if ( bytes(addressToCodeUsed[user]).length == 0) {
                if ( referralCodeToOwner[code_] != address(0) ) {
                    if ( referralCodeToOwner[code_] == user ) revert CantReferYourself();
                    addressToCodeUsed[user] = code_;
                    emit ReferralCodeUsed( user, code_ );
                } else {
                    revert ReferralCodeDoesNotExist();
                }
            }
        }
    }

    // Just used for the generation of the random code for referrals
    function random(uint number) internal returns(uint){
        counter++;
        return uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender,counter))) % number;
    }
    // size is length of word
    function randomString(uint size) internal returns(string memory){
        bytes memory randomWord=new bytes(size);
        // since we have 46 letters
        bytes memory chars = new bytes(46);
        chars="ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890123456789";
        for (uint i=0;i<size;i++){
            uint randomNumber=random(46);
            // Index access for string is not possible
            randomWord[i]=chars[randomNumber];
        }
        return string(randomWord);
    }
}