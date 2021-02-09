// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

/// @title Diamond Cut Facet Interface
/// @dev Implementation of this is required to enable upgrading a diamond
interface IDiamondCut {
    /// @dev Add=0, Replace=1, Remove=2
    enum FacetCutAction {Add, Replace, Remove}

    /// @dev Structure used to either Add, Replace, or Remove a facet and it's
    /// functions
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @dev Emitted once when diamondCut is called
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    /// a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    /// calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

}
