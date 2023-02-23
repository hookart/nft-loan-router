// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./RepayAndSell.sol";

contract Flashloan is IERC3156FlashBorrower, RepayAndSellNftFi {
    // set the lender to the euler flashloan contract
    IERC3156FlashLender internal constant lender =
        IERC3156FlashLender(EULER_ADDR);

    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

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

        // Decode calldata to get NFTFi loanId and Reservoir saleExecutionInfos
        (
            uint32 tokenId,
            ReservoirV6.ExecutionInfo[] calldata saleExecutionInfos
        ) = abi.decode(_data, (uint32, ReservoirV6.ExecutionInfo[]));

        // execute logic
        // (1) repay the original loan
        repayLoan(tokenId);

        // (2) sell the collateral to the reservoir api using the passed order
        sellCollateral(saleExecutionInfos);

        // repay flashloan
        _token.transfer(msg.sender, _amount);

        // return ERC-3156 success value
        return CALLBACK_SUCCESS;
    }
}
