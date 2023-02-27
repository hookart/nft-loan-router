// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./external/euler-xyz/Interfaces.sol";
import "./external/reservoir/IReservoirRouterV6.sol";
import "solmate/tokens/ERC721.sol";

abstract contract Flashloan is IERC3156FlashBorrower {
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    IERC3156FlashLender immutable lender;

    /// @notice The amount we need to pay back to the lender
    uint256 payback;

    /// @notice Receiver Construction
    constructor(address flashLoanLender) {
        lender = IERC3156FlashLender(flashLoanLender);
    }

    function flashLoan(
        address borrowingErc20TokenAddress,
        uint256 amount,
        bytes memory data
    ) internal returns (bool) {
        return
            lender.flashLoan(
                IERC3156FlashBorrower(address(this)),
                borrowingErc20TokenAddress,
                amount,
                data
            );
    }

    function internalExecuteRepayAndSell(
        uint32 tokenId,
        address tokenAddress,
        ReservoirV6.ExecutionInfo[] memory saleExecutionInfos
    ) internal virtual;

    /// @notice Receive a flashloan
    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external returns (bytes32) {
        require(msg.sender == address(EULER_ADDR), "untrusted lender");
        require(_initiator == address(this), "untrusted loan initiator");

        // Decode calldata to get NFTFi loanId and Reservoir saleExecutionInfos
        (
            uint32 tokenId,
            address tokenAddress,
            ReservoirV6.ExecutionInfo[] memory saleExecutionInfos
        ) = abi.decode(_data, (uint32, address, ReservoirV6.ExecutionInfo[]));

        // execute logic
        internalExecuteRepayAndSell(tokenId, tokenAddress, saleExecutionInfos);

        // check if sale proceeds are enough to pay back the loan
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance >= _amount, "not enough funds to repay loan");

        // approve flashloan sender for token so they can repay flashloan
        IERC20(_token).approve(address(EULER_ADDR), type(uint256).max);

        // return ERC-3156 success value
        return CALLBACK_SUCCESS;
    }
}
