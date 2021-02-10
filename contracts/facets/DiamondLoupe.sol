// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";
import {IDiamondLoupe} from "../../interfaces/IDiamondLoupe.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @title Diamond Loupe for inspecting diamond facets
/// @dev These functions are expected to be called by external tools
contract DiamondLoupe is IDiamondLoupe {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Gets all facet addresses and their four byte function selectors
    /// @return facets_ An array of Facet
    function facets()
        external
        view
        override
        returns (IDiamondLoupe.Facet[] memory facets_) {

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
                    functionSelectors: LibDiamond.facetAddressToSelectors(_facets.at(facetIndex))
                });
            }
        }
}
