import brownie
from brownie.network.account import Account
from brownie.network.contract import ProjectContract, ContractContainer, Contract
import pytest


@pytest.fixture(scope="module")
def mock_contract_facet(
    adam: Account, MockContract: ContractContainer
) -> ProjectContract:
    """Deploy the Mock Conract"""
    return adam.deploy(MockContract)


@pytest.fixture(scope="module")
def diamond_mock(diamond: ProjectContract, MockContract: ContractContainer) -> Contract:
    """Diamond contract with Mock Contract Facet functions available.

    Note: Debugging is not available since the bytecodes of diamond and Mock Contract
    do not match.
    https://eth-brownie.readthedocs.io/en/stable/api-network.html#ContractContainer.at
    """
    return Contract.from_abi("Diamond Mock", diamond.address, MockContract.abi)


@pytest.fixture
def add_facet_cut_data(mock_contract_facet, facet_cut_action):
    facetcut = [
        (
            mock_contract_facet.address,
            facet_cut_action.ADD,
            list(mock_contract_facet.selectors.keys()),
        )
    ]
    return facetcut


def test_get_all_facet_addresses_and_function_selectors(
    diamond_loupe, diamond_cut_facet, diamond_loupe_facet
):

    # call the facets external view function on diamond contract
    result = diamond_loupe.facets()

    # split the result into two variables
    addresses, selectors = list(zip(*result))

    # create sets of response for easier membership testing
    all_result_addresses = set(addresses)
    all_result_selectors = {str(selector) for array in selectors for selector in array}

    # create sets of expected response for membership testing
    expected_addresses = {diamond_cut_facet.address, diamond_loupe_facet.address}
    expected_selectors = {
        selector
        for array in (
            diamond_cut_facet.selectors.keys(),
            diamond_loupe_facet.selectors.keys(),
        )
        for selector in array
    }

    assert all_result_addresses == expected_addresses
    assert all_result_selectors == expected_selectors


def test_get_all_function_selectors_supported_by_a_facet(
    diamond_loupe, diamond_cut_facet, diamond_loupe_facet
):
    diamond_cut_facet_selectors = diamond_loupe.facetFunctionSelectors(
        diamond_cut_facet.address
    )
    diamond_loupe_facet_selectors = diamond_loupe.facetFunctionSelectors(
        diamond_loupe_facet.address
    )

    assert {str(sel) for sel in diamond_cut_facet_selectors} == set(
        diamond_cut_facet.selectors.keys()
    )

    assert {str(sel) for sel in diamond_loupe_facet_selectors} == set(
        diamond_loupe_facet.selectors.keys()
    )


def test_get_all_function_selectors_supported_by_a_facet_fails_for_invalid_facet(
    diamond_loupe, zero_address
):
    with brownie.reverts("LibDiamond: Invalid facet address"):
        diamond_loupe.facetFunctionSelectors(zero_address)


def test_get_all_facet_addresses_used_by_diamond(
    diamond_loupe, diamond_cut_facet, diamond_loupe_facet
):
    facet_addresses = diamond_loupe.facetAddresses()

    expected_addresses = {diamond_cut_facet.address, diamond_loupe_facet.address}

    assert set(facet_addresses) == expected_addresses


def test_get_facet_address_for_a_given_selector(
    diamond_loupe, diamond_cut_facet, diamond_loupe_facet
):

    for selector in diamond_cut_facet.selectors.keys():
        assert diamond_loupe.facetAddress(selector) == diamond_cut_facet.address

    for selector in diamond_loupe_facet.selectors.keys():
        assert diamond_loupe.facetAddress(selector) == diamond_loupe_facet.address


def test_get_facet_address_for_a_given_selector_fails_for_unsupported_function_selector(
    diamond_loupe,
):
    with brownie.reverts("Unsupported function selector"):
        diamond_loupe.facetAddress("0x00000000")


def test_add_functions_updates_facets(
    adam,
    diamond_loupe,
    diamond_cut,
    zero_address,
    add_facet_cut_data,
    mock_contract_facet,
):
    diamond_cut.diamondCut(add_facet_cut_data, zero_address, b"", {"from": adam})
    facet_addresses = diamond_loupe.facetAddresses()

    assert mock_contract_facet.address in facet_addresses


def test_add_functions_updates_selectors(
    adam,
    diamond_loupe,
    diamond_cut,
    zero_address,
    add_facet_cut_data,
    mock_contract_facet,
):
    diamond_cut.diamondCut(add_facet_cut_data, zero_address, b"", {"from": adam})
    facet_selectors = diamond_loupe.facetFunctionSelectors(mock_contract_facet.address)

    assert set(mock_contract_facet.selectors.keys()) == {
        str(sel) for sel in facet_selectors
    }


def test_add_functions_emits_diamond_cut_event(
    adam, diamond_cut, zero_address, add_facet_cut_data,
):
    tx = diamond_cut.diamondCut(add_facet_cut_data, zero_address, b"", {"from": adam})

    assert "DiamondCut" in tx.events
    assert len(tx.events) == 1


def test_add_functions_calls_initialization_with_calldata(
    adam, diamond_cut, add_facet_cut_data, mock_contract_facet, diamond_mock,
):
    calldata = diamond_mock.setter.encode_input(100)

    diamond_cut.diamondCut(
        add_facet_cut_data, mock_contract_facet.address, calldata, {"from": adam}
    )

    assert diamond_mock.getter() == 100


def test_add_functions_doesnt_call_initialization(
    adam, diamond_cut, add_facet_cut_data, zero_address, diamond_mock,
):
    diamond_cut.diamondCut(add_facet_cut_data, zero_address, b"", {"from": adam})

    assert diamond_mock.getter() == 0


def test_add_functions_reverts_with_facet_address_zero(
    adam, diamond_cut, zero_address, mock_contract_facet, facet_cut_action
):
    facetcut = [
        (
            zero_address,
            facet_cut_action.ADD,
            list(mock_contract_facet.selectors.keys()),
        )
    ]
    with brownie.reverts("LibDiamond: Facet address can't be address(0)"):
        diamond_cut.diamondCut(facetcut, zero_address, b"", {"from": adam})


def test_add_functions_reverts_with_no_selectors(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_add_functions_reverts_when_given_a_supported_selector(
    adam, diamond_cut, zero_address, mock_contract_facet, facet_cut_action
):
    facetcut = [(mock_contract_facet.address, facet_cut_action.ADD, [],)]
    with brownie.reverts("LibDiamond: No selectors to add"):
        diamond_cut.diamondCut(facetcut, zero_address, b"", {"from": adam})


def test_add_functions_reverts_when_init_is_zero_address_and_given_calldata(
    adam, diamond_cut, add_facet_cut_data, zero_address, diamond_mock,
):
    calldata = diamond_mock.setter.encode_input(100)
    with brownie.reverts("LibDiamond: _init is address(0) but_calldata is not empty"):
        diamond_cut.diamondCut(
            add_facet_cut_data, zero_address, calldata, {"from": adam}
        )


def test_add_functions_reverts_when_init_is_not_contract(
    adam, diamond_cut, add_facet_cut_data, diamond_mock,
):
    calldata = diamond_mock.setter.encode_input(100)
    with brownie.reverts("LibDiamond: _init address has no code"):
        diamond_cut.diamondCut(add_facet_cut_data, adam, calldata, {"from": adam})


def test_add_functions_reverts_when_init_is_contract_and_not_given_calldata(
    adam, diamond_cut, add_facet_cut_data, mock_contract_facet, diamond_mock,
):
    with brownie.reverts(
        "LibDiamondCut: _calldata is empty but _init is not address(0)"
    ):
        diamond_cut.diamondCut(
            add_facet_cut_data, mock_contract_facet.address, b"", {"from": adam}
        )


def test_replace_functions_emits_diamond_cut_event(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_functions_calls_initialization_with_calldata(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_functions_doesnt_call_initialization(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_functions_replaces_single_selector(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_functions_replaces_all_selectors_and_removes_facet(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_reverts_with_facet_address_zero(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_reverts_with_no_selectors(diamond_loupe, diamond_cut, MockContract):
    pass


def test_replace_reverts_when_given_an_unsupported_selector(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_reverts_when_init_is_not_contract(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_reverts_when_init_is_zero_address_and_given_calldata(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_replace_reverts_when_init_is_contract_and_not_given_calldata(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_remove_emits_diamond_cut_event(diamond_loupe, diamond_cut, MockContract):
    pass


def test_remove_calls_initialization_with_calldata(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_remove_doesnt_call_initialization(diamond_loupe, diamond_cut, MockContract):
    pass


def test_remove_single_selector(diamond_loupe, diamond_cut, MockContract):
    pass


def test_remove_all_selectors_for_a_facet_and_removes_facet(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_remove_reverts_with_facet_address_not_zero_address(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_remove_reverts_with_no_selectors(diamond_loupe, diamond_cut, MockContract):
    pass


def test_remove_reverts_when_given_an_unsupported_selector(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_remove_reverts_when_init_is_not_contract(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_remove_reverts_when_init_is_zero_address_and_given_calldata(
    diamond_loupe, diamond_cut, MockContract
):
    pass


def test_remove_reverts_when_init_is_contract_and_not_given_calldata(
    diamond_loupe, diamond_cut, MockContract
):
    pass
