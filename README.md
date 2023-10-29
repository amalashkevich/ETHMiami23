## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

3209

export PK1="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PK2="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export PK3="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
export A1=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export A2=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
export A3=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC

export INITIAL_OWNER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
forge create --rpc-url http://localhost:8545 \
             --constructor-args $INITIAL_OWNER \
             --private-key $PK1 \
             src/Title.sol:Title

export TITLE="0x5FbDB2315678afecb367f032d93F642f64180aa3"

# safeMint(address to, string memory uri) Title
cast send --private-key $PK1 $TITLE "safeMint(address,string)" $A1 hello --rpc-url http://127.0.0.1:8545/
cast send --private-key $PK1 $TITLE "safeMint(address,string)" $A2 hello --rpc-url http://127.0.0.1:8545/
cast send --private-key $PK1 $TITLE "safeMint(address,string)" $A3 hello --rpc-url http://127.0.0.1:8545/

forge create --rpc-url http://localhost:8545 \
             --constructor-args $INITIAL_OWNER \
             --private-key $PK1 \
             src/Property.sol:Property

export PROPERTY="0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9"

# safeMint(address to, string memory uri) Property
cast send --private-key $PK1 $PROPERTY "safeMint(address,string)" $A1 hello --rpc-url http://127.0.0.1:8545/
cast send --private-key $PK1 $PROPERTY "safeMint(address,string)" $A2 hello --rpc-url http://127.0.0.1:8545/
cast send --private-key $PK1 $PROPERTY "safeMint(address,string)" $A3 hello --rpc-url http://127.0.0.1:8545/


forge create --rpc-url http://localhost:8545 \
             --constructor-args $TITLE $PROPERTY $INITIAL_OWNER \
             --private-key $PK1 \
             src/TitleInsurance.sol:TitleInsurance

export TI="0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"

cast send --private-key $PK1 $TI "backPool()" --value 0.01ether
cast send --private-key $PK2 $TI "backPool()" --value 0.01ether
cast send --private-key $PK3 $TI "backPool()" --value 0.01ether

# createPolicy(uint256 owner, uint256 propertyId, uint256 premiumAmount, uint256 coverAmount)
cast send --private-key $PK1 $TI "createPolicy(address,uint256,uint256,uint256)" $A2 2 0.01ether 10ether --rpc-url http://127.0.0.1:8545/
cast send --private-key $PK1 $TI "createPolicy(address,uint256,uint256,uint256)" $A3 2 0.01ether 10ether --rpc-url http://127.0.0.1:8545/

# payPremium(uint256 policyId)
cast send --private-key $PK2 $TI "payPremium(uint256)" 1 --value 0.01ether --rpc-url http://127.0.0.1:8545/
cast send --private-key $PK3 $TI "payPremium(uint256)" 2 --value 0.01ether --rpc-url http://127.0.0.1:8545/


# payPremium(uint256 policyId)
cast send --private-key $PK2 $TI "payPremium(uint256)" 1 --value 0.01ether --rpc-url http://127.0.0.1:8545/
cast send --private-key $PK3 $TI "payPremium(uint256)" 2 --value 0.01ether --rpc-url http://127.0.0.1:8545/


# withdrawInterest()
cast send --private-key $PK3 $TI "withdrawInterest()" --rpc-url http://127.0.0.1:8545/
# No interest so far

# terminatePolicy(uint256 policyId)
cast send --private-key $PK2 $TI "terminatePolicy(uint256)" 1 --rpc-url http://127.0.0.1:8545/