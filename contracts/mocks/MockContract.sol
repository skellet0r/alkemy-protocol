// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

/// @dev Uses unstructured storage pattern
contract MockContract {
    function getter() external view returns (uint256 val_) {
        bytes32 position = keccak256("diamond.standard.mock.contract.storage");
        assembly {
            val_ := sload(position)
        }
    }

    function setter(uint256 val_) external {
        bytes32 position = keccak256("diamond.standard.mock.contract.storage");
        assembly {
            sstore(position, val_)
        }
    }
}
