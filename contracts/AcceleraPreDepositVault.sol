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

    event DepositsEnabled(bool enabled);
    event WithdrawalsEnabled(bool enabled);
    event ReferralCodeCreationEnabled(bool enabled);
    event ReferralCodeMandatoryEnabled(bool enabled);

    event ReferralCodeCreated( address user, string code );
    event ReferralCodeUsed( address user, string code );

    constructor(address initialOwner_, IERC20 asset_, string memory name_, string memory symbol_)
        ERC4626(asset_)
        ERC20(name_, symbol_)
        Ownable(initialOwner_)
    {}

    function useReferralCode ( address receiver, string memory code_) internal {
        if ( bytes(code_).length != 0 ) {
            if ( bytes(addressToCodeUsed[receiver]).length == 0) {
                if ( referralCodeToOwner[code_] != address(0) ) {
                    addressToCodeUsed[receiver] = code_;
                    emit ReferralCodeUsed( receiver, code_ );
                } else {
                    revert ReferralCodeDoesNotExist();
                }
            }
        }
    }

    function depositWithReferral(uint256 assets, address receiver, string memory code_) public virtual returns (uint256) {

        useReferralCode ( receiver, code_);

        uint256 shares = deposit(assets, receiver);

        return shares;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        
        if (!depositsEnabled) {
            revert DepositsDisabled();
        }

        if (referralCodeMandatory && bytes(addressToCodeUsed[receiver]).length == 0) {
            revert ReferralCodeMandatory();
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

    function createReferralCode() external {

        if (!referralCodeCreationEnabled) revert ReferralCodeCreationDisabled();

        address user_ = _msgSender();
        string memory code_ = randomString(6);

        if( referralCodeToOwner[code_] != address(0) ) revert ReferralCodeAlreadyUsed();
        
        if ( bytes(ownerToReferralCode[user_]).length != 0 ) revert AddressAlreadyHasReferralCode();
        
        referralCodeToOwner[code_] = user_;
        ownerToReferralCode[user_] = code_;

        emit ReferralCodeCreated(user_, code_);
    }

    function createReferralCodeOwner( address user_, string memory code_ ) external onlyOwner {

        if ( bytes(code_).length == 0 ) code_ = randomString(6);

        if( referralCodeToOwner[code_] != address(0) ) revert ReferralCodeAlreadyUsed();
        
        if ( bytes(ownerToReferralCode[user_]).length != 0 ) revert AddressAlreadyHasReferralCode();
        
        referralCodeToOwner[code_] = user_;
        ownerToReferralCode[user_] = code_;

        emit ReferralCodeCreated(user_, code_);
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