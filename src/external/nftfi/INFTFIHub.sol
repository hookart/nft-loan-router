// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

interface INftfiHub {
    function setContract(string calldata _contractKey, address _contractAddress)
        external;

    function getContract(bytes32 _contractKey) external view returns (address);
}
