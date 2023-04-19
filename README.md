# Tree Planting Application
## Plutus Demo Project

The Tree Planting application is a smart contract built on the Plutus platform that allows users to create unique NFTs for trees and accept donations in native tokens. The contract keeps track of each tree's donor and the total amount of tokens donated.

## Overview

The Tree Planting application consists of two main components: the on-chain code and the off-chain code. The on-chain code is responsible for managing the state of the contract on the blockchain, while the off-chain code handles client interactions with the contract.

The on-chain code includes the validator script, which defines the rules for validating transactions that interact with the contract. The validator script is implemented using the Plutus Scripting language, a variant of Haskell that is designed for writing smart contracts on the Cardano blockchain.

The off-chain code includes the client schema, which defines the endpoints that clients can use to interact with the contract, and the contract code, which implements the logic for the endpoints. The client schema and contract code are implemented using the Plutus DSL, a domain-specific language for writing smart contracts on the Plutus platform.

## Validator Script

The validator script is the core of the Tree Planting application. It defines the rules for validating transactions that interact with the contract. The validator script is implemented using the Plutus Scripting language, a variant of Haskell that is designed for writing smart contracts on the Cardano blockchain.

The validator script for the Tree Planting application defines two types of data: the `TreePlantingDatum` and the `TreePlantingRedeemer`.

The `TreePlantingDatum` is the data that is stored on the blockchain for each tree. It includes the ID of the tree, the donor's name, and the total amount of tokens donated.

The `TreePlantingRedeemer` is the data that is provided by the user in the transaction that interacts with the contract. It includes the type of action that the user wants to perform, either creating a new tree or donating to an existing tree.

The validator script includes a validate function that defines the rules for validating transactions that interact with the contract. The validate function takes as input the current `TreePlantingDatum`, the `TreePlantingRedeemer`, and the scriptContext, which includes information about the transaction being validated.

The `validate` function uses pattern matching to determine which action the user wants to perform. If the user wants to create a new tree, the function checks that the `TreePlantingRedeemer` is of type Create and that the `TreePlantingDatum` is empty. If the user wants to donate to an existing tree, the function checks that the `TreePlantingRedeemer` is of type Donate and that the `TreePlantingDatum` is not empty.

If the transaction is valid, the validate function returns True. Otherwise, it returns False.

## On-Chain Code

The on-chain code is responsible for managing the state of the contract on the blockchain. It includes the `tpInst`, `tpValidator`, and `tpAddress` functions.

The `tpInst` function defines the script instance for the Tree Planting validator script. It uses the Scripts.validator function to create a new script instance that includes the compiled validate function, the `TreePlantingDatum`, and the `TreePlantingRedeemer`. It also includes a wrap function that wraps the validator script with the `TreePlantingDatum` and `TreePlantingRedeemer` types.

The `tpValidator` function defines the validator script for the Tree Planting application. It uses he Scripts.validatorScript function to compile the validate function into a script that can be deployed on the blockchain. It also includes a TreePlantingAddress type that is used to represent the address of the Tree Planting contract on the blockchain.

The tpAddress function is responsible for generating the address of the Tree Planting contract. It uses the Address.scriptAddress function to generate an address for the compiled validator script.

## Off-Chain Code

The off-chain code is responsible for handling client interactions with the Tree Planting contract. It includes the client schema, which defines the endpoints that clients can use to interact with the contract, and the contract code, which implements the logic for the endpoints.

The client schema includes two endpoints: createTree and donateToTree. The createTree endpoint allows users to create a new tree, while the donateToTree endpoint allows users to donate to an existing tree.

The createTree endpoint takes as input the name of the donor and the amount of tokens to donate. It uses the PlutusTx.fromData function to convert the input into the TreePlantingRedeemer type, and the PlutusTx.toData function to convert the output into the TreePlantingDatum type. It then uses the submitTxConstraints function to submit a transaction to the blockchain that creates a new tree.

The donateToTree endpoint takes as input the ID of the tree to donate to and the amount of tokens to donate. It uses the PlutusTx.fromData function to convert the input into the TreePlantingRedeemer type, and the PlutusTx.toData function to convert the output into the TreePlantingDatum type. It then uses the submitTxConstraints function to submit a transaction to the blockchain that donates to the specified tree.

The contract code includes the createTree and donateToTree functions, which implement the logic for the corresponding endpoints. The createTree function creates a new tree by constructing a TxConstraints value that specifies the constraints for the transaction. It uses the mustPayToTheScript function to specify the amount of tokens to donate, and the mustValidateIn function to specify the validator script that should be used to validate the transaction.

The donateToTree function donates to an existing tree by constructing a TxConstraints value that specifies the constraints for the transaction. It uses the mustPayToOtherScript function to specify the amount of tokens to donate and the address of the tree's validator script, and the mustValidateIn function to specify the validator script that should be used to validate the transaction.

## Native Tokens
The Tree Planting application uses native tokens to accept donations. Native tokens are tokens that are created on the Cardano blockchain and can be used to represent any asset, such as a cryptocurrency or a real-world asset.

The Tree Planting application defines a TreeCoin token that is used to represent the tokens donated to the Tree Planting contract. The TreeCoin token is defined using the AssetClass type, which includes the CurrencySymbol and TokenName for the token.

The createTree and donateToTree functions use the AssetClass.assetClass function to create an AssetClass value for the TreeCoin token, and the Ada.adaValueOf function to create a Value for the amount of tokens to donate.

## Conclusion
The Tree Planting application is a smart contract built on the Plutus platform that allows users to donate to and track trees. The application includes both on-chain and off-chain code, as well as the use of native tokens.

The on-chain code includes the validator script that defines the logic for the Tree Planting contract. The validator script specifies the rules for creating and donating to trees, including ensuring that each tree has a unique ID and that donations are tracked for each tree separately.

The off-chain code includes the client schema and contract code that allow users to interact with the Tree Planting contract. The client schema includes two endpoints for creating new trees and donating to existing trees. The contract code includes the `createTree` and `donateToTree` functions that implement the logic for the corresponding endpoints.

The Tree Planting application uses native tokens to accept donations. The `TreeCoin` token is defined using the `AssetClass` type, and the `createTree` and `donateToTree` functions use the `AssetClass.assetClass` function to create an `AssetClass` value for the token.

Overall, the Tree Planting application is an example of how Plutus can be used to build smart contracts that are both secure and flexible, and that can be used to represent a wide range of assets and applications on the Cardano blockchain.
