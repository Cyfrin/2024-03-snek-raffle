import boa
import pytest

# In vyper, logs are 1 indexed
RAFFLE_OPEN = 1
RAFFLE_CALCULATING = 2

INTERVAL = 86400

USER = boa.env.generate_address("user")
STARTING_BALANCE = 1_000_000_000_000_000_000  # 1 ether


def test_raffle_reverts_when_you_dont_pay_enough(raffle_boa):
    boa.env.set_balance(USER, STARTING_BALANCE)
    with boa.env.prank(USER):
        with boa.reverts("SnekRaffle: Send more to enter raffle"):
            raffle_boa.enter_raffle()


def test_raffle_records_player_when_they_enter(raffle_boa, entrance_fee):
    boa.env.set_balance(USER, STARTING_BALANCE)
    with boa.env.prank(USER):
        raffle_boa.enter_raffle(value=entrance_fee)
    assert raffle_boa.get_players(0) == USER


# Boa support is limited for logs for now
# def test_emits_event_on_entrance(raffle_boa, entrance_fee):
#     boa.env.set_balance(USER, STARTING_BALANCE)
#     with boa.env.prank(USER):
#         raffle_boa.enter_raffle(value=entrance_fee)
#     assert raffle_boa.get_logs()[0].topics[0] == USER


@pytest.fixture
def raffle_boa_entered(raffle_boa, entrance_fee):
    boa.env.set_balance(USER, STARTING_BALANCE)
    with boa.env.prank(USER):
        raffle_boa.enter_raffle(value=entrance_fee)
    return raffle_boa


def test_fulfill_random_words_picks_a_winner_resets_and_sends_money(
    raffle_boa_entered, vrf_coordinator_boa, entrance_fee
):
    additional_entrants = 10

    for i in range(additional_entrants):
        player = boa.env.generate_address(i)
        boa.env.set_balance(player, STARTING_BALANCE)
        with boa.env.prank(player):
            raffle_boa_entered.enter_raffle(value=entrance_fee)
    starting_balance = boa.env.get_balance(USER)
    boa.env.time_travel(seconds=INTERVAL + 1)

    raffle_boa_entered.request_raffle_winner()

    # Normally we need to get the requestID, but our mock ignores that
    vrf_coordinator_boa.fulfillRandomWords(0, raffle_boa_entered.address)

    recent_winner = raffle_boa_entered.get_recent_winner()
    winner_balance = boa.env.get_balance(recent_winner)
    prize = entrance_fee * (additional_entrants + 1)
    assert recent_winner == USER
    assert winner_balance == starting_balance + prize
