# SPDX-License-Identifier: MIT
# @version ^0.4.0b1
"""
@title Snek Raffle 
@author Cutie Potootie Snek-person
@notice We love some snekz
"""

from .interfaces import VRFCoordinatorV2
from libraries.snekmate.tokens import ERC721

initializes: ERC721

exports: (
    ERC721.balanceOf,
    ERC721.ownerOf,
    ERC721.transferFrom,
    ERC721.approve,
    ERC721.safeTransferFrom,
    ERC721.setApprovalForAll,
    # ERC721.tokenURI, we are overriding this function
    ERC721.totalSupply,
    ERC721.tokenOfOwnerByIndex,
    ERC721.burn,
    # ERC721.safe_mint, not using this 
    ERC721.set_minter,
    ERC721.permit,
    ERC721.transfer_ownership,
    ERC721.renounce_ownership,
)

# Errors
ERROR_NOT_ENDED: constant(String[25]) = "SnekRaffle: Not ended"
ERROR_TRANSFER_FAILED: constant(String[100]) = "SnekRaffle: Transfer failed"
ERROR_SEND_MORE_TO_ENTER_RAFFLE: constant(String[100]) = "SnekRaffle: Send more to enter raffle"
ERROR_RAFFLE_NOT_OPEN: constant(String[100]) = "SnekRaffle: Raffle not open"
ERROR_NOT_COORDINATOR: constant(String[46]) = "SnekRaffle: OnlyCoordinatorCanFulfill"

# Type declarations
flag RaffleState:
    OPEN 
    CALCULATING

# State Variables
## Constants
MAX_ARRAY_SIZE: constant(uint256) = 1
REQUEST_CONFIRMATIONS: constant(uint16) = 3
CALLBACK_GAS_LIMIT: constant(uint32) = 100000
NUM_WORDS: constant(uint32) = 1
MAX_NUMBER_OF_PLAYERS: constant(uint256) = 10000
EMPTY_BYTES: constant(Bytes[32]) = b"\x00"

## Snek NFT Stats
COMMON_SNEK_URI: public(constant(String[53])) = "ipfs://QmSQcYNrMGo5ZuGm1PqYtktvg1tWKGR7PJ9hQosKqMz2nD"
RARE_SNEK_URI: public(constant(String[53])) = "ipfs://QmZit9nbdhJsRTt3JBQN458dfZ1i6LR3iPGxGQwq34Li4a"
LEGEND_SNEK_URI: public(constant(String[53])) = "ipfs://QmRujARrkux8nsUG8BzXJa8TiDyz5sDJnVKDqrk3LLsKLX"
COMMON_RARITY: public(constant(uint256)) = 70
RARE_RARITY: public(constant(uint256)) = 25
LEGEND_RARITY: public(constant(uint256)) = 5
COMMON: constant(uint256) = 0
RARE: constant(uint256) = 1
LEGEND: constant(uint256) = 2

rarityToTokenURI: public(HashMap[uint256, String[53]]) 
tokenIdToRarity: public(HashMap[uint256, uint256])

## Immutables 
VRF_COORDINATOR: immutable(VRFCoordinatorV2)
GAS_LANE: immutable(bytes32)
SUBSCRIPTION_ID: immutable(uint64)
ENTRANCE_FEE: immutable(uint256)
RAFFLE_DURATION: immutable(uint256)

## Storage Variables
last_timestamp: uint256
recent_winner: address
players: DynArray[address, MAX_NUMBER_OF_PLAYERS]
raffle_state: RaffleState

# Events
event RequestedRaffleWinner:
    request_id: indexed(uint256)
event RaffleEntered:
    player: indexed(address)
event WinnerPicked:
    player: indexed(address)

# Constructor
@deploy
@payable
def __init__(
    subscription_id: uint64,
    gas_lane: bytes32,  # keyHash
    entrance_fee: uint256,
    vrf_coordinator_v2: address,
):
    ERC721.__init__("Snek Raffle", "SNEK", "", "snek raffle", "v0.0.1")
    SUBSCRIPTION_ID = subscription_id
    GAS_LANE = gas_lane
    ENTRANCE_FEE = entrance_fee
    VRF_COORDINATOR = VRFCoordinatorV2(vrf_coordinator_v2)
    RAFFLE_DURATION = 86400 # ~1 day
    self.raffle_state = RaffleState.OPEN
    self.last_timestamp = block.timestamp
    self.rarityToTokenURI[COMMON] = COMMON_SNEK_URI
    self.rarityToTokenURI[RARE] = RARE_SNEK_URI
    self.rarityToTokenURI[LEGEND] = LEGEND_SNEK_URI


# External Functions
@external
@payable
def enter_raffle():
    """Enter the raffle by sending the entrance fee."""
    assert msg.value == ENTRANCE_FEE, ERROR_SEND_MORE_TO_ENTER_RAFFLE
    assert self.raffle_state == RaffleState.OPEN, ERROR_RAFFLE_NOT_OPEN
    self.players.append(msg.sender)
    log RaffleEntered(msg.sender)

@external 
def request_raffle_winner() -> uint256:
    """Request a random winner from the VRF Coordinator after a raffle has completed."""
    is_open: bool = RaffleState.OPEN == self.raffle_state
    time_passed: bool = (block.timestamp - self.last_timestamp) > RAFFLE_DURATION
    has_players: bool = len(self.players) > 0
    has_balance: bool = self.balance > 0
    assert is_open and time_passed and has_players and has_balance, ERROR_NOT_ENDED

    self.raffle_state = RaffleState.CALCULATING
    request_id: uint256 = VRF_COORDINATOR.requestRandomWords(
        GAS_LANE,
        SUBSCRIPTION_ID,
        REQUEST_CONFIRMATIONS,
        CALLBACK_GAS_LIMIT,
        NUM_WORDS
    )
    return ERC721._total_supply()


@external
def rawFulfillRandomWords(requestId: uint256, randomWords: uint256[MAX_ARRAY_SIZE]):
    """The function the VRF Coordinator calls back to to provide the random words."""
    assert msg.sender == VRF_COORDINATOR.address, ERROR_NOT_COORDINATOR
    self.fulfillRandomWords(requestId, randomWords)

@internal
def fulfillRandomWords(request_id: uint256, random_words: uint256[MAX_ARRAY_SIZE]):
    index_of_winner: uint256 = random_words[0] % len(self.players)
    recent_winner: address = self.players[index_of_winner]
    self.recent_winner = recent_winner
    self.players = []
    self.raffle_state = RaffleState.OPEN
    self.last_timestamp = block.timestamp
    rarity: uint256 = random_words[0] % 3
    self.tokenIdToRarity[ERC721._total_supply()] = rarity 
    log WinnerPicked(recent_winner)
    ERC721._mint(recent_winner, ERC721._total_supply())
    send(recent_winner, self.balance)

#####################
# View Functions    #
#####################
@external
@view
def tokenURI(token_id: uint256) -> String[53]:
    rarity: uint256 = self.tokenIdToRarity[token_id]
    return self.rarityToTokenURI[rarity]

@external 
@view 
def get_players(index: uint256) -> address:
    return self.players[index]

@external
@view
def get_recent_winner() -> address:
    return self.recent_winner

@external
@view 
def get_raffle_state() -> RaffleState:
    return self.raffle_state

