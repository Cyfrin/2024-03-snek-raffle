
<p align="center">
<img src="https://res.cloudinary.com/droqoz7lg/image/upload/q_90/dpr_2.0/c_fill,g_auto,h_320,w_320/f_auto/v1/company/ocawxe9a5ab2uh3tiozt?_a=BATAUVAA0" width="400" alt="Snek Raffle">
<br/>

# Contest Details

### Prize Pool

- High - 100xp
- Medium - 20xp
- Low - 2xp

- Starts: March 07, 2024 Noon UTC
- Ends: March 14, 2024 Noon UTC

### Stats

- nSLOC: 136
- Complexity Score: 🐍

- [Contest Details](#contest-details)
    - [Prize Pool](#prize-pool)
    - [Stats](#stats)
- [About](#about)
  - [New Vyper Compiler Features](#new-vyper-compiler-features)
  - [snek_raffle.vy](#snek_rafflevy)
  - [It's a NFT](#its-a-nft)
  - [Chainlink VRF](#chainlink-vrf)
  - [Winnable Sneks](#winnable-sneks)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Note](#note)
  - [Testing](#testing)
- [Audit Scope Details](#audit-scope-details)
  - [Compatibilities](#compatibilities)
- [Roles](#roles)
- [Known Issues](#known-issues)


# About
The Puppy Raffle NFT team is back! And this time, they've learnt from their mistakes... It couldn't have been their fault their last contract had so many bugs, so puppies and solidity must have just been bad luck! They decided to try this again, with sneks and Vyper! Surely that was the issue last time? 😜

The Puppy Raffle team loves being on the cutting edge, so this codebase is built with a [new beta release of the vyper compiler](https://x.com/vyperlang/status/1762203569715855826)!

## New Vyper Compiler Features

Introducing... Imports!! The vyper compiler now features imports, and you can see we use imports from the [🐍 snekmate](https://github.com/pcaversaccio/snekmate) repo. We `pip` installed the library by invoking:

```console
pip3 install git+https://github.com/pcaversaccio/snekmate.git@modules -t contracts/libraries
```

And then we removed all the files except the ones we needed.

We will use 🐍 snekmate's latest [`ERC721.vy`](./contracts/libraries/snekmate/tokens/ERC721.vy) contract, which is compatible with the latest Vyper compiler version, but the contract itself is considered out of scope for this audit.

You can see how we import the [`ERC721.vy`](./contracts/libraries/snekmate/tokens/ERC721.vy) contract in the [`snek_raffle.vy`](./contracts/snek_raffle.vy) contract:

```python
from libraries.snekmate.tokens import ERC721 # Imports the contract 
initializes: ERC721          # This means that our contract initializes with the __init__ func of the ERC721 contract


exports: (                   # In vyper, you have specify what external functions you want your contract to use/inherit
    ERC721.balanceOf,
    ERC721.ownerOf,
    .
    .
)

.
.
.
    ERC721.__init__("Snek Raffle", "SNEK", "", "snek raffle", "v0.0.1") # This is how we initialize the ERC721 contract in our constructor 
```

You cannot inherit/override internal functions. This is a specific design choice by the Vyper team - so that knowing exactly what a function is supposed to do is easier. 

## snek_raffle.vy

The `snek_raffle.vy` is the main contract that the team is looking for a security review on, and the only contract considered in-scope. The contract functionality is as such:

1. `enter_raffle`: Users pay the `ENTRANCE_FEE` to enter the snek raffle 
2. `request_raffle_winner`: This is the function to kick off a [chainlink VRF](https://docs.chain.link/vrf) call to get a random winner. This function can be called only when the following conditions are met:
   1. The `raffle_state` is set to `OPEN`
   2. Enough `RAFFLE_DURATION` has passed since the raffle was opened
   3. There are at least 1 `players`
   4. There is more than 0 `balance` in the contract
3. `rawFulfillRandomWords`: The function that the Chainlink VRF calls back to give the contest a random winner. The following happens when this function is called:
   1. The winner receives:
      1. A random snek NFT 
      2. The balance of the contract (should be all the entrace fees added together)
   2. The contract is "reset" to it's initial state:
      1. The raffle is considered `OPEN`
      2. `players` array is reset 
      3. `last_timestamp` is reset 

## It's a NFT

When someone wins a snek, it should have all the functionality of a normal NFT. It should be able to be viewed, transferred, approved, etc.

_Note: If you find an issue with [`ERC721.vy`](./contracts/libraries/snekmate/tokens/ERC721.vy), ignore it. If the [`snek_raffle.vy`](./contracts/snek_raffle.vy) forgets to import/export a function, or uses it wrong, consider that a bug. But if the function itself is wrong in [`ERC721.vy`](./contracts/libraries/snekmate/tokens/ERC721.vy), that's fine. We are pretending that contract is perfect for this review._

## Chainlink VRF

The contracts rely on the Chainlink VRF to get a random number. Assume the contract/subscription will always be properly funded with LINK tokens. 

## Winnable Sneks 


There are 3 NFTs that can be won in the snek raffle, each with varying rarity. 

1. Brown Snek - 70% Chance to get
2. Jungle Snek - 25% Chance to get
3. Cosmic Snek - 5% Chance to get

The Chainlink VRF is used to get a random number, and the random number is used to determine the winner.

# Getting Started 

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [python3](https://www.python.org/downloads/)
  - You'll know you've done it right if you can run `python3 --version` and you see a response like `Python x.x.x`
- [pip3](https://pip.pypa.io/en/stable/installation/)
  - You'll know you've done it right if you can run `pip3 --version` and you see a response like `pip x.x.x from /path/to/site-packages/pip (python x.x)`

## Installation

If this is your first time using a python virtual environment, you can [learn more about it here,](https://docs.python.org/3/library/venv.html) and we highly advise that you work with an AI to help you get set up. AIs like ChatGPT tend to be very good at python debugging. 

1. Clone the repository
```
git clone https://github.com/Cyfrin/2024-03-snek-raffle
cd 2024-03-snek-raffle
```

2. Setup the virtual environment, and install packages
```
make venv
source ./venv/bin/activate
make install
```

_Be sure to run `source ./venv/bin/activate` before you install!_

or, if `make` doesn't work:
```
python3 -m venv ./venv
source ./venv/bin/activate
pip3 install vyper==0.4.0b1
pip3 install git+https://github.com/vyperlang/titanoboa@vyper-0.4.0
```

> Q: Why not a `requirements.txt` file?
> A: Because this is an experimental package and the dependencies are all messed up right now. 

You'll be in something called a "virtual environment" which will have all the packages you need for this project to run tests. To "leave" the python virtual environment, just run `deactivate`. 

### Note

The above will install the new experimental vyper compiler and titanoboa testing framework, so it might take a little longer to install than normal. 

## Manual Compiling

You can manually compile the vyper contract with this command:

```
vyper contracts/snek_raffle.vy 
```

or
```
python3 -m vyper contracts/snek_raffle.vy
```

## Testing

```
pytest
```

or

```
python3 -m pytest
```

# Audit Scope Details

- In Scope:

```ml
└── contracts
    └── snek_raffle.vy
```

## Compatibilities

- Vyper Version: [`0.4.0b1`](https://github.com/vyperlang/vyper/releases/tag/0.4.0b1) (Experimental new Vyper compiler version)
- Chain(s) to deploy contract to:
  - Ethereum
  - Arbitrum
  - ZKSync

# Roles

- Chainlink VRF: The Chainlink VRF is responsible for providing a random number to the contract.
- Users: People who can enter the raffle for the sneks. 

# Known Issues

- This is a beta release of the vyper compiler which hasn't undergone a security review itself, and we expect there to be some issues with the compiler itself, ignore those. 
