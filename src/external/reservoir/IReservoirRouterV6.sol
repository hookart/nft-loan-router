// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ReservoirV6 {
    // --- Public ---

    struct ExecutionInfo {
        address module;
        bytes data;
        uint256 value;
    }

    // Trigger a set of executions atomically
    function execute(ExecutionInfo[] calldata executionInfos) external payable;

    struct AmountCheckInfo {
        address checkContract;
        bytes checkData;
        uint256 amountThreshold;
    }

    // Trigger a set of executions with amount checking. As opposed to the regular
    // `execute` method, `executeWithAmountCheck` supports stopping the executions
    // once the provided amount check reaches a certain value. This is useful when
    // trying to fill orders with slippage (eg. provide multiple orders and try to
    // fill until a certain balance is reached). In order to be flexible, checking
    // the amount is done generically by calling `checkContract` with `checkData`.
    // For example, this could be used to check the ERC721 total owned balance (by
    // using `balanceOf(owner)`), the ERC1155 total owned balance per token id (by
    // using `balanceOf(owner, tokenId)`), but also for checking the ERC1155 total
    // owned balance per multiple token ids (by using a custom contract that wraps
    // `balanceOfBatch(owners, tokenIds)`).
    function executeWithAmountCheck(
        ExecutionInfo[] calldata executionInfos,
        AmountCheckInfo calldata amountCheckInfo
    ) external payable;
}
