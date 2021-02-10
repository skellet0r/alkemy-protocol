import brownie


def test_get_all_facet_addresses_and_function_selectors(
    diamond_loupe, diamond_cut_facet, diamond_loupe_facet
):

    # call the facets external view function on diamond contract
    result = diamond_loupe.facets()

    # split the result into two variables
    addresses, selectors = list(zip(*result))

    # create sets of response for easier membership testing
    all_result_addresses = set(addresses)
    all_result_selectors = {selector for array in selectors for selector in array}

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

    assert set(diamond_cut_facet_selectors) == set(diamond_cut_facet.selectors.keys())
    assert set(diamond_loupe_facet_selectors) == set(
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
    with brownie.reverts("LibDiamond: Unsupported function selector"):
        diamond_loupe.facetAddress("0x00000000")