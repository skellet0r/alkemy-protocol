// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";

/// @dev Custom collection of functions related to EnumerableSet types
library LibEnumerableSet {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * @dev Converts a Bytes32Set to a Bytes4 array.
     * Useful for transforming a set of selectors into an array.
     * 
     * Converting to a higher order, pads the higher order bits.
     * uint16 a = 0x1234;
     * uint32 b = uint32(a); // b will be 0x00001234 now
     *
     * Converting to a lower order, cuts off the higher order bits.
     * uint32 a = 0x12345678;
     * uint16 b = uint16(a); // b will be 0x5678 now
     */
    function toBytes4Array(EnumerableSet.Bytes32Set storage _self) internal view returns (bytes4[] memory array) {
        // initialize return array to be the same size as our set
        array = new bytes4[](_self.length());
        // for loop which assigns each bytes32 element into the return array
        for (
            uint256 index;
            index < _self.length();
            index++
        ) {
            array[index] = bytes4(_self.at(index));
        }
    }
}