// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

/// @title Diamond Loupe for inspecting diamond facets
/// @dev These functions are expected to be called by external tools
interface IDiamondLoupe {
    /// @dev Structure of a facet
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors
    /// @return facets_ An array of Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet
    /// @param _facet The facet address
    /// @return facetFunctionSelectors_ An array of bytes4 function selectors
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond
    /// @return facetAddresses_ An array of facet Addresses
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector
    /// @dev If facet is not found return address(0)
    /// @param _functionSelector The function selector
    /// @return facetAddress_ The facet address
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
