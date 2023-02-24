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

        //
        ///\
        //Hack: send the nft to reservior.. why? there is a re-entrancy issue currently within reservior
        // this lets us get around it
        ERC721(address(tokenAddress)).transferFrom(
            address(this),
            address(0x20794EF7693441799a3f38FCC22a12b3E04b9572),
            215000879
        );
        ///
        reservoir.execute(saleExecutionInfos);

        // repay flashloan
        IERC20(_token).transfer(msg.sender, _amount);

        // return ERC-3156 success value
        return CALLBACK_SUCCESS;
    }
}
