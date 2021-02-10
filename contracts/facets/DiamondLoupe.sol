// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";
import {IDiamondLoupe} from "../../interfaces/IDiamondLoupe.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibEnumerableSet} from "../libraries/LibEnumerableSet.sol";

/// @title Diamond Loupe for inspecting diamond facets
/// @dev These functions are expected to be called by external tools
contract DiamondLoupe is IDiamondLoupe {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using LibEnumerableSet for EnumerableSet.AddressSet;

    /// @notice Gets all facet addresses and their four byte function selectors
    /// @return facets_ An array of Facet
    function facets()
        external
        view
        override
        returns (IDiamondLoupe.Facet[] memory facets_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.getDiamondStorage();
        // get the supported diamond facets
        EnumerableSet.AddressSet storage _facets = ds.facets;
        // initialize size of the return array
        facets_ = new IDiamondLoupe.Facet[](_facets.length());
        // loop through each suppported facet and get it's selectors
        for (uint256 facetIndex; facetIndex < _facets.length(); facetIndex++) {
            // assign the facet to the index
            facets_[facetIndex] = IDiamondLoupe.Facet({
                facetAddress: _facets.at(facetIndex),
                functionSelectors: LibDiamond.facetAddressToSelectors(
                    _facets.at(facetIndex)
                )
            });
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet
    /// @param _facet The facet address
    /// @return facetFunctionSelectors_ An array of bytes4 function selectors
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        facetFunctionSelectors_ = LibDiamond.facetAddressToSelectors(_facet);
    }

    /// @notice Get all the facet addresses used by a diamond
    /// @return facetAddresses_ An array of facet Addresses
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.getDiamondStorage();
        // get the facets
        EnumerableSet.AddressSet storage facets = ds.facets;
        // assign the array to the return value
        facetAddresses_ = facets.toArray();
    }

    /// @notice Gets the facet that supports the given selector
    /// @dev If facet is not found return address(0)
    /// @param _functionSelector The function selector
    /// @return facetAddress_ The facet address
    function facetAddress(bytes4 _functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.getDiamondStorage();
        // selector must exist
        require(ds.selectorToFacetAddress[_functionSelector] != address(0), "Unsupported function selector");
        // assign and return
        facetAddress_ = ds.selectorToFacetAddress[_functionSelector];
    }
}
