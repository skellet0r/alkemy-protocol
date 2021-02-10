// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IDiamondLoupe} from "../../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";
import {LibEnumerableSet} from "./LibEnumerableSet.sol";
import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";
import {Address} from "openzeppelin/contracts/utils/Address.sol";

/// @title Storage library related to the Diamond Standard implementation
/// @author Edward Amor
/// @dev A library with only internal functions gets embedded into a
/// contract by the compiler
library LibDiamond {
    using Address for address;
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

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

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
    function facetAddressToSelectors(address _facet)
        internal
        view
        returns (bytes4[] memory selectors_)
    {
        // load the diamond storage
        DiamondStorage storage ds = getDiamondStorage();
        // require the facet is valid
        require(
            ds.facets.contains(_facet),
            "LibDiamond: Invalid facet address"
        );
        // get the facet selectors
        EnumerableSet.Bytes32Set storage selectors =
            ds.facetAddressToFunctionSelectors[_facet];
        return selectors.toBytes4Array();
    }

    /// @dev library version of diamondCut function
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        // loop through all the cuts
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            // what action is being performed
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                // add the functions
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                // Replace some functions
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                // Remove some functions
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                // revert because the wrong action was given
                revert("LibDiamond: Incorrect facet cut action");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        // initialize the diamond
        initDiamondCut(_init, _calldata);
    }

    /// @dev Add a collection of functions to diamond
    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // need functions to add
        require(
            _functionSelectors.length > 0,
            "LibDiamond: No selectors to add"
        );
        // get the storage
        DiamondStorage storage ds = getDiamondStorage();
        // facet address can't be zero address
        require(
            _facetAddress != address(0),
            "LibDiamond: Facet address can't be address(0)"
        );
        // verify the contract has code to execute
        require(
            _facetAddress.isContract(),
            "LibDiamond: Facet address has no contract code"
        );
        // we can't add selectors for a facet that already exists
        require(
            !ds.facets.contains(_facetAddress),
            "LibDiamond: Facet address already present"
        );
        // loop through each selector
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            // get the current iterations function selector
            bytes4 selector = _functionSelectors[selectorIndex];
            // check what the selectors facet address is
            address oldFacetAddress = ds.selectorToFacetAddress[selector];
            // verify there is no previous facet contract with this function selector
            require(
                oldFacetAddress == address(0),
                "LibDiamond: Function selector already exists"
            );
            // add the facet address and selector position in selector array for the selector
            ds.selectorToFacetAddress[selector] = _facetAddress;
            ds.facetAddressToFunctionSelectors[_facetAddress].add(
                bytes32(selector) // will left pad the bytes4 selector
            );
        }
        // add the facet address successfully to the set of facets
        ds.facets.add(_facetAddress);
    }

    /// @dev Replace a function selector in a diamond
    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // need functions to add
        require(
            _functionSelectors.length > 0,
            "LibDiamond: No selectors to add"
        );
        // get the storage
        DiamondStorage storage ds = getDiamondStorage();
        // facet address can't be zero address
        require(
            _facetAddress != address(0),
            "LibDiamond: Replacement facet can't be address(0)"
        );

        require(
            _facetAddress.isContract(),
            "LibDiamond: Replacement facet has no contract code"
        );
        // loop through each selector
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            // get the current selector
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAddress[selector];
            // can't replace immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddress != address(this),
                "LibDiamond: Can't replace an immutable function"
            );
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamond: Can't replace function with same function"
            );
            require(
                oldFacetAddress != address(0),
                "LibDiamond: Can't replace function that doesn't exist"
            );
            // replace old facet address
            ds.selectorToFacetAddress[selector] = _facetAddress;
            bool removeOld =
                ds.facetAddressToFunctionSelectors[oldFacetAddress].remove(
                    bytes32(selector)
                );
            // The removal has to return true
            require(
                removeOld,
                "LibDiamond: Failed to remove selector from old facet address"
            );
            bool addNew =
                ds.facetAddressToFunctionSelectors[_facetAddress].add(
                    bytes32(selector)
                );
            // The addition has to return true
            require(
                addNew,
                "LibDiamond: Failed to add selector to new facet address"
            );
        }
        // if the oldFacetAddress has no more selectors remove it
        if (ds.facetAddressToFunctionSelectors[oldFacetAddress].length() == 0) {
            ds.facets.remove(oldFacetAddress);
        }
    }
}
