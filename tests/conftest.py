from enum import IntEnum
from brownie.network.account import Account, Accounts, EthAddress
from brownie.network.contract import Contract, ContractContainer, ProjectContract
import pytest


class FacetCutAction(IntEnum):
    """Enumeraion for calling diamondCut."""

    ADD = 0
    REPLACE = 1
    REMOVE = 2


@pytest.fixture(scope="module")
def adam(accounts: Accounts) -> Account:
    """Get the first available account."""
    return accounts[0]


@pytest.fixture(scope="module")
def barry(accounts: Accounts) -> Account:
    """Get the second available account."""
    return accounts[1]


@pytest.fixture(scope="module")
def charlie(accounts: Accounts) -> Account:
    return accounts[2]


@pytest.fixture(scope="module")
def zero_address() -> EthAddress:
    """The canonical ethereum zero address."""
    return EthAddress("0x0000000000000000000000000000000000000000")


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    """Isolate each function by rolling back the chain."""
    pass


@pytest.fixture(scope="session")
def facet_cut_action() -> FacetCutAction:
    """Simply return the FacetCutAction class."""
    return FacetCutAction


@pytest.fixture(scope="module")
def diamond_cut_facet(adam: Account, DiamondCut: ContractContainer) -> ProjectContract:
    """Deploy the DiamondCut contract."""
    return adam.deploy(DiamondCut)


@pytest.fixture(scope="module")
def diamond_loupe_facet(
    adam: Account, DiamondLoupe: ContractContainer
) -> ProjectContract:
    """Deploy the DiamondLoupe contract."""
    return adam.deploy(DiamondLoupe)


@pytest.fixture(scope="module")
def diamond(
    adam: Account,
    diamond_cut_facet: ProjectContract,
    diamond_loupe_facet: ProjectContract,
    Diamond: ContractContainer,
    DiamondCut: ContractContainer,
    DiamondLoupe: ContractContainer,
    facet_cut_action: FacetCutAction,
) -> ProjectContract:
    """Deploy the Diamond contract with Cut and Loupe facets."""
    init_facet_cuts = [
        (
            diamond_cut_facet.address,
            facet_cut_action.ADD,
            tuple(DiamondCut.selectors.keys()),
        ),
        (
            diamond_loupe_facet.address,
            facet_cut_action.ADD,
            tuple(DiamondLoupe.selectors.keys()),
        ),
    ]
    return adam.deploy(Diamond, init_facet_cuts)


@pytest.fixture(scope="module")
def diamond_cut(diamond: ProjectContract, DiamondCut: ContractContainer) -> Contract:
    """Diamond contract with Diamond Cut Facet functions available.

    Note: Debugging is not available since the bytecodes of diamond and DiamondCut
    do not match.
    https://eth-brownie.readthedocs.io/en/stable/api-network.html#ContractContainer.at
    """
    return DiamondCut.at(diamond.address)


@pytest.fixture(scope="module")
def diamond_loupe(
    diamond: ProjectContract, DiamondLoupe: ContractContainer
) -> Contract:
    """Diamond contract with Diamond Loupe Facet functions available.

    Note: Debugging is not available since the bytecodes of diamond and DiamondLoupe
    do not match.
    https://eth-brownie.readthedocs.io/en/stable/api-network.html#ContractContainer.at
    """
    return DiamondLoupe.at(diamond.address)
