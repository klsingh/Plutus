-- | The TreePlanting module contains the smart contract code for the Tree Planting application.
module TreePlanting where

import PlutusTx.Prelude hiding (Semigroup(..), unless)
import PlutusTx.AssocMap as M
import PlutusTx.Builtins.Class (fromBuiltinData)
import PlutusTx.Builtins (BuiltinData)
import PlutusTx.Builtins.Internal (BuiltinByteString(..))
import Plutus.Contract hiding (when)
import qualified Plutus.V1.Ledger.Value as Value
import Plutus.V1.Ledger.Contexts
import Plutus.V1.Ledger.Tx
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString.Short as S
import qualified Data.Map as Map
import qualified Data.Set as Set
import Control.Monad (void, guard)
import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Data.Default.Class (Default (..))
import qualified Data.Text as T

-- | The TreePlanting datum is used to track information about a tree, including its ID, donor, and amount donated.
data TreePlantingDatum = TreePlantingDatum
    { tpTreeId :: Integer
    , tpDonor :: Address
    , tpAmount :: Value
    } deriving (Show, Generic, FromJSON, ToJSON, Eq)

-- | The TreePlanting redeemer is used to indicate whether a transaction is donating to a tree or creating a new tree.
data TreePlantingRedeemer = Donate | Create deriving (Show, Generic, FromJSON, ToJSON, Eq)

-- | The TreePlanting output is a pair of a datum and a token.
type TreePlantingOutput = (TreePlantingDatum, Value)

-- | The TreePlanting input is a pair of a validator and an output.
type TreePlantingInput = (ValidatorHash, TreePlantingOutput)

-- | The TreePlanting state is an association map from validator hashes to datums and values.
type TreePlantingState = Map.Map ValidatorHash (TreePlantingDatum, Value)

-- | The TreePlanting schema defines the endpoints for the smart contract.
type TreePlantingSchema =
    BlockchainActions
        .\/ Endpoint "create" Integer
        .\/ Endpoint "donate" (ValidatorHash, Integer)

-- | The TreePlanting contract takes a starting balance as a parameter and returns the contract instance and an initial state.
treePlantingContract :: Value -> Contract () TreePlantingSchema Text (TreePlantingState, BuiltinByteString)
treePlantingContract startBalance = do
    -- Define the validator script.
    let validator = mkValidatorScript $$(PlutusTx.compile [|| validate ||])
        -- Define the address for the validator script.
        address = scriptAddress validator
    -- Define the on-chain and off-chain endpoints for the contract.
    createEndpoint <- endpoint @"create"
    donateEndpoint <- endpoint @"donate"
    -- Define the initial state.
    let initialState = Map.empty
    -- Define the contract loop.
    void $ Contract.loop initialState $ \state -> do
        -- Handle the on-chain create endpoint.
        createValue <- createEndpoint
        case createValue of
            -- If the input is valid, create a new tree.
            Left err -> Contract.logError $ "Error creating tree: " ++ unpack err
            Right treeId -> do
                let treeDatum = TreePlantingDatum { tpTreeId = treeId, tpDonations = [] }
                tpTreeId = treeId
                tpDonor = address
                tpAmount = startBalance
                output = (treeDatum, startBalance) 
                -- Create the transaction and submit it to the blockchain.
                tx <- submitTxConstraints validator $ Set.singleton $ TxOut
                    { txOutAddress = address
                    , txOutValue = startBalance <> Value.singleton (Value.mintingPolicyHash startBalance) 1
                    , txOutDatumHash = Just $ datumHash $ toData treeDatum
                    }
                void $ awaitTxConfirmed $ txId tx
                -- Update the state with the new tree.
                let newState = Map.insert (validatorHash validator) (treeDatum, startBalance) state
                -- Return the new state and the minting policy for the token.
                return (newState, Value.mintingPolicy startBalance)

        -- Handle the on-chain donate endpoint.
        donateValue <- donateEndpoint
        case donateValue of
            -- If the input is invalid, log an error.
            Left err -> Contract.logError $ "Error donating to tree: " ++ unpack err
            Right (validatorHash, amount) -> do
                -- Get the current state for the specified validator.
                let currentState = Map.lookup validatorHash state
                -- Check that the validator is a valid TreePlanting validator.
                guard $ case currentState of
                    Just (datum, _) -> validatorHash == validatorHash (validatorScript validator) && tpTreeId datum > 0
                    _ -> False
                -- Create the new output and update the state.
                let Just (treeDatum, treeValue) = currentState
                    newTreeValue = treeValue <> amount
                    newOutput = (treeDatum {tpAmount = newTreeValue}, newTreeValue)
                    newState = Map.insert validatorHash newOutput state
                -- Create the transaction and submit it to the blockchain.
                tx <- submitTxConstraints validator $ Set.fromList
                    [ TxOut
                        { txOutAddress = address
                        , txOutValue = newTreeValue <> Value.singleton (Value.mintingPolicyHash newTreeValue) 1
                        , txOutDatumHash = Just $ datumHash $ toData (tpTreeId treeDatum, newTreeValue)
                        }
                    , TxOut
                        { txOutAddress = tpDonor treeDatum
                        , txOutValue = amount
                        , txOutDatumHash = Nothing
                        }
                    ]
                void $ awaitTxConfirmed $ txId tx
                -- Return the new state and the minting policy for the token.
                return (newState, Value.mintingPolicy newTreeValue)

-- | The validate function is used to validate transactions.
validate :: TreePlantingDatum -> TreePlantingRedeemer -> ScriptContext -> Bool
validate treeDatum treeRedeemer ctx = case treeRedeemer of
    -- A donate redeemer is only valid if the input value is greater than zero and the validator is a valid TreePlanting validator.
    Donate -> isJust (findOwnInput ctx) && maybe False (\i -> (iValue i) > (Ada Lovelace 0)) (findOwnInput ctx) &&
              case findOwnInput ctx of
                  Just input -> let validatorHash = txOutValidatorHash $ txInInfoResolved input
                                    stateValue = findDatum validatorHash ctx >>= fromBuiltinData @TreePlantingOutput
                                in case stateValue of
                                    Just (datum, _) -> validatorHash == validatorHash (ownValidator ctx) && tpTreeId datum > 0
                                    _ -> False
                  _ -> False
    -- A create redeemer
        Create -> True
    -- An empty redeemer is always valid.
    Close -> True

-- | The tree planting script instance.
tpInst :: Scripts.ScriptInstance TreePlanting
tpInst = Scripts.validator @TreePlanting
    ($$(PlutusTx.compile [|| validate ||])
        `PlutusTx.applyCode` PlutusTx.liftCode treeDatum
        `PlutusTx.applyCode` PlutusTx.liftCode treeRedeemer)
    $$(PlutusTx.compile [|| wrap ||])
  where
    wrap = Scripts.wrapValidator @TreePlantingDatum @TreePlantingRedeemer

-- | The tree planting validator script.
tpValidator :: Validator
tpValidator = Scripts.validatorScript tpInst

-- | The tree planting address.
tpAddress :: Address
tpAddress = scriptAddress tpValidator

-- | The tree planting client schema.
type TreePlantingSchema =
    BlockchainActions
        .\/ Endpoint "create" Tree
        .\/ Endpoint "donate" (ValidatorHash, Value)

-- | The tree planting contract.
treePlantingContract :: Contract () TreePlantingSchema Text ()
treePlantingContract = do
    -- Create a new tree.
    createEndpoint <- endpoint @"create"
    let createTx = do
            tree <- createEndpoint
            let treeDatum = TreePlantingDatum { tpTreeId = tpId tree, tpDonor = "", tpAmount = Ada Lovelace 0 }
                startBalance = Ada.adaValueOf 1
            (newState, mintingPolicy) <- createTree tpValidator tpAddress startBalance treeDatum Map.empty
            return (newState, mintingPolicy)
    createTxId <- activateContractWallet createTx
    void $ awaitTxConfirmed $ txId createTxId

    -- Donate to an existing tree.
    donateEndpoint <- endpoint @"donate"
    let donateTx = do
            donateValue <- donateEndpoint
            case donateValue of
                Left err -> Contract.logError $ "Error donating to tree: " ++ unpack err
                Right _ -> pure ()
    void $ activateContractWallet donateTx

-- | The off-chain code for the tree planting contract.
treePlantingContractOffChain :: Contract () TreePlantingSchema Text ()
treePlantingContractOffChain = treePlantingContract

-- | The on-chain code for the tree planting contract.
treePlantingContractOnChain :: AsContractError e => Contract () TreePlantingSchema e ()
treePlantingContractOnChain = do
    logInfo @String "Starting tree planting contract"
    -- Define the tree planting validator script and the initial state.
    let initialTree = TreePlantingDatum { tpTreeId = 0, tpDonor = "", tpAmount = Ada Lovelace 0 }
        initState = Map.singleton (validatorHash tpValidator) (initialTree, Ada.adaValueOf 1)
    -- Define the endpoints and start the contract instance.
    TreePlanting.startContract tpValidator tpInst initState treePlantingContract

