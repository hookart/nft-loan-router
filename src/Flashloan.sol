// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./RepayAndSell.sol";

contract Flashloan is IERC3156FlashBorrower, RepayAndSellNftFi {
    // set the lender to the euler flashloan contract
    // IERC3156FlashLender internal constant lender =
    //     IERC3156FlashLender(EULER_ADDR);

    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    /// @notice The contract owner
    // ddaddress public immutable owner;

    /// @notice The amount we need to pay back to the lender
    uint256 payback;

    /// @notice Receiver Construction
    constructor() {
        // lender = IERC3156FlashLender(EULER_ADDR);
        // owner = owner_;
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
            address tokenAddress,
            ReservoirV6.ExecutionInfo[] memory saleExecutionInfos
        ) = abi.decode(_data, (uint32, address, ReservoirV6.ExecutionInfo[]));

        // execute logic

        // (1) repay the original loan
        IERC20(_token).approve(
            address(0x8252Df1d8b29057d1Afe3062bf5a64D503152BC8),
            type(uint256).max
        );

        ERC721(address(tokenAddress)).setApprovalForAll(
            address(reservoir),
            true
        );

        repayLoan(tokenId);

        // (2) sell the collateral to the reservoir api using the passed order

        // give reservior access to this token.
        ERC721(address(tokenAddress)).setApprovalForAll(
            address(reservior),
            true
        );
        reservoir.execute(saleExecutionInfos);

        // check if sale proceeds are enough to pay back the loan
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance >= _amount, "not enough funds to repay loan");

        // approve flashloan sender for token so they can repay flashloan
        IERC20(_token).approve(address(EULER_ADDR), type(uint256).max);

        // return ERC-3156 success value
        return CALLBACK_SUCCESS;
    }
}
