// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IDiamondLoupe} from "../../interfaces/IDiamondLoupe.sol";
import {LibEnumerableSet} from "./LibEnumerableSet.sol";
import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";


/// @title Storage library related to the Diamond Standard implementation
/// @author Edward Amor
/// @dev A library with only internal functions gets embedded into a
/// contract by the compiler
library LibDiamond {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using LibEnumerableSet for EnumerableSet.Bytes32Set;
    
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");
    
    struct DiamondStorage {
        // Useful for getting all the function selectors at an address
        mapping(address => EnumerableSet.Bytes32Set) facetAddressToFunctionSelectors;
        // Query the address for which function selector is available
        mapping(bytes4 => address) selectorToFacetAddress;
        // All the available facet addresses
        EnumerableSet.AddressSet facets;
    }

    /// @dev Retrieve the diamond storage
    function getDiamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        // Only direct number constants and references to such constants are supported
        // by inline assembly.
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns the bytes4 function selectors for a facet
    function facetAddressToSelectors(address _facet) internal view returns (bytes4[] memory selectors_) {
        // load the diamond storage
        DiamondStorage storage ds = getDiamondStorage(); 
        // require the facet is valid
        require(ds.facets.contains(_facet), "LibDiamond: Invalid facet address");
        // get the facet selectors
        EnumerableSet.Bytes32Set storage selectors = ds.facetAddressToFunctionSelectors[_facet];
        return selectors.toBytes4Array();
    }
}