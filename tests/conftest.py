import boa
import pytest

VRF_COORDINATOR_LOCATION = "./contracts/test/VRFCoordinatorV2Mock.vy"
RAFFLE_LOCATION = "./contracts/snek_raffle.vy"
BASE_FEE = 1_00000000000000000  # 0.1
GAS_PRICE_LINK = 1_000000000  # Some value calculated depending on the Layer 1 cost and Link. This is 1e9
RAFFLE_ENTRANCE_FEE = 1_000_000_000_000_000_000


@pytest.fixture
def vrf_coordinator_boa() -> boa.contracts.vyper.vyper_contract.VyperContract:
    return boa.load(VRF_COORDINATOR_LOCATION, GAS_PRICE_LINK, BASE_FEE)


@pytest.fixture
def entrance_fee():
    return RAFFLE_ENTRANCE_FEE


@pytest.fixture
def raffle_boa(vrf_coordinator_boa) -> boa.contracts.vyper.vyper_contract.VyperContract:
    sub_id = 0
    gas_lane = b""
    return boa.load(
        RAFFLE_LOCATION,
        sub_id,
        gas_lane,
        RAFFLE_ENTRANCE_FEE,
        vrf_coordinator_boa.address,
    )
