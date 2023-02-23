// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./external/euler-xyz/Interfaces.sol";
import "./RepayAndSell.sol";

contract Flashloan is IERC3156FlashBorrower, RepayAndSellNftFi {
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /// @notice The contract owner
    address public immutable owner;

    /// @notice The amount we need to pay back to the lender
    uint256 payback;

    /// @notice Receiver Construction
    constructor(IERC3156FlashLender lender_, address owner_) {
        // lender = IERC3156FlashLender(EULER_ADDR);
        owner = owner_;
    }

    /// @notice Receive a flashloan
    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external returns (bytes32) {
        // receive flashloan
        require(msg.sender == address(EULER_ADDR), "untrusted lender");
        require(_initiator == address(this), "untrusted loan initiator");
        
         // Decode calldata to get tokenIds, derivative address, function data
        (address underlying, uint256 amount) = abi.decode(
            _data,
            (address, uint256)
        );

        // execute logic
        // (1) repay the original loan
        // (2) sell the collateral to the reservoir api using the passed order

        // repay flashloan
        IERC20(underlying).transfer(msg.sender, _amount);

        // return ERC-3156 success value
        return CALLBACK_SUCCESS;
    }
}
