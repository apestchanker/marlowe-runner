module Component.ContractList where

import Prelude

import Actus.Domain (CashFlow)
import Actus.Domain.ContractTerms (ContractTerms)
import CardanoMultiplatformLib (CborHex)
import CardanoMultiplatformLib.Transaction (TransactionWitnessSetObject)
import Component.CreateContract as CreateContract
import Component.Modal (mkModal)
import Component.Types (ActusContractId(..), ContractInfo(..), MessageContent(..), MessageHub(..), MkComponentM, WalletInfo(..))
import Component.Types.ContractInfo (MarloweInfo(..))
import Component.Types.ContractInfo as ContractInfo
import Component.Widget.Table (orderingHeader) as Table
import Component.Widgets (link, linkWithIcon)
import Contrib.Fetch (FetchError)
import React.Basic.DOM as R
import Contrib.React.Bootstrap (overlayTrigger, tooltip)
import Contrib.React.Bootstrap.Icons as Icons
import Contrib.React.Bootstrap.Table (striped) as Table
import Contrib.React.Bootstrap.Table (table)
import Contrib.React.Bootstrap.Types as OverlayTrigger
import Control.Monad.Reader.Class (asks)
import Data.Array (elem, singleton, toUnfoldable)
import Data.Array as Array
import Data.BigInt.Argonaut as BigInt
import Data.DateTime (adjust)
import Data.Decimal (Decimal)
import Data.Either (Either(..))
import Data.Foldable (fold, foldMap)
import Data.Function (on)
import Data.List (List)
import Data.Maybe (Maybe(..), fromMaybe, isNothing, maybe)
import Data.Newtype (un, unwrap)
import Data.Time.Duration as Duration
import Data.Tuple (snd)
import Data.Tuple.Nested (type (/\))
import Debug (traceM)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Now (nowDateTime)
import Language.Marlowe.Core.V1.Semantics.Types (Case(..), Contract(..), Input(..), InputContent(..), Party, Token)
import Language.Marlowe.Core.V1.Semantics.Types (Contract, Input(..), InputContent(..), Party)
import Language.Marlowe.Core.V1.Semantics.Types as V1
import Marlowe.Actus.Metadata as M
import Marlowe.Runtime.Web.Client (post')
import Marlowe.Runtime.Web.Client (put')
import Marlowe.Runtime.Web.Types (ContractHeader(..), Metadata, PostTransactionsRequest(..), TxOutRef, txOutRefToString, txOutRefToUrlEncodedString)
import Marlowe.Runtime.Web.Types (PostMerkleizationRequest(..), PostMerkleizationResponse(..), PostTransactionsRequest(..), PostTransactionsResponse(..), PutTransactionRequest(..), Runtime(..), ServerURL, TextEnvelope(..), TransactionEndpoint, TransactionsEndpoint, toTextEnvelope)
import Marlowe.Runtime.Web.Types as Runtime
import Marlowe.Runtime.Web.Types as Runtime
import React.Basic (fragment) as DOOM
import React.Basic.DOM (div_, span_, text) as DOOM
import React.Basic.DOM (text)
import React.Basic.DOM.Events (targetValue)
import React.Basic.DOM.Simplified.Generated as DOM
import React.Basic.Events (EventHandler, handler)
import React.Basic.Events (handler_)
import React.Basic.Hooks (Hook, JSX, UseState, component, useState, (/\))
import React.Basic.Hooks (JSX, component, useContext, useState, (/\))
import React.Basic.Hooks as React
import Wallet as Wallet
import WalletContext (WalletContext(..), walletAddresses)

type ContractId = TxOutRef

type ProjectedCashFlows = List (CashFlow Decimal Party)

type ValidationError = String

data FormState
  = NotValidated
  | Failure ValidationError
  | Validated (ContractTerms /\ Contract)

-- An example of a simple "custom hook"
useInput :: String -> Hook (UseState String) (String /\ EventHandler)
useInput initialValue = React.do
  value /\ setValue <- useState initialValue
  let onChange = handler targetValue (setValue <<< const <<< fromMaybe "")
  pure (value /\ onChange)

type SubmissionError = String

type ContractListState =
  { newContract :: Boolean
  , newInput :: 
      Maybe 
        { transactionsEndpoint :: TransactionsEndpoint
        , marloweInfo :: Maybe MarloweInfo
        }
  , metadata :: Maybe Metadata
  }

type Props =
  { contractList :: Array ContractInfo
  , connectedWallet :: Maybe (WalletInfo Wallet.Api)
  }

data OrderBy
  = OrderByCreationDate
  | OrderByLastUpdateDate

derive instance Eq OrderBy

submit :: CborHex TransactionWitnessSetObject -> ServerURL -> TransactionEndpoint -> Aff (Either FetchError Unit)
submit witnesses serverUrl transactionEndpoint = do
  let
    textEnvelope = toTextEnvelope witnesses ""

    req = PutTransactionRequest textEnvelope
  put' serverUrl transactionEndpoint req

mkContractList :: MkComponentM (Props -> JSX)
mkContractList = do
  Runtime runtime <- asks _.runtime
  modal <- liftEffect $ mkModal
  MessageHub msgHubProps <- asks _.msgHub

  createContractComponent <- CreateContract.mkComponent
  walletInfoCtx <- asks _.walletInfoCtx
  cardanoMultiplatformLib <- asks _.cardanoMultiplatformLib

  liftEffect $ component "ContractList" \{ connectedWallet, contractList } -> React.do
    ((state :: ContractListState) /\ updateState) <- useState { newContract: false, newInput: Nothing, metadata: Nothing }

    ordering /\ updateOrdering <- useState { orderBy: OrderByCreationDate, orderAsc: false }

    possibleWalletContext <- useContext walletInfoCtx <#> map (un WalletContext <<< snd)

    let
      contractList' = do
        let
          -- Quick and dirty hack to display just submited contracts as first
          someFutureBlockNumber = Runtime.BlockNumber 9058430
          sortedContracts = case ordering.orderBy of
            OrderByCreationDate -> Array.sortBy (compare `on` (fromMaybe someFutureBlockNumber <<< map (_.blockNo <<< un Runtime.BlockHeader) <<< ContractInfo.createdAt)) contractList
            OrderByLastUpdateDate -> Array.sortBy (compare `on` (fromMaybe someFutureBlockNumber <<< map (_.blockNo <<< un Runtime.BlockHeader) <<< ContractInfo.updatedAt)) contractList
        if ordering.orderAsc then sortedContracts
        else Array.reverse sortedContracts

    let
      onAddContractClick = updateState _ { newContract = true }

      onApplyInputs { transactionsEndpoint, marloweInfo } { party, token, value } cw = handler_ do
        now <- nowDateTime
        -- FIXME: move aff flow into `useAff` on the component level
        launchAff_ $ do
          case possibleWalletContext of
            Just { changeAddress: Just changeAddress } -> do
              let WalletInfo { wallet: walletApi } = cw
              addresses <- walletAddresses cardanoMultiplatformLib walletApi

              let
                inputs = singleton $ NormalInput (IDeposit party party token value)

                invalidBefore = fromMaybe now $ adjust (Duration.Minutes (-2.0)) now
                invalidHereafter = fromMaybe now $ adjust (Duration.Minutes 2.0) now
                collateralUTxOs = []

                req = PostTransactionsRequest
                  { inputs
                  , invalidBefore
                  , invalidHereafter
                  , metadata: mempty
                  , tags: mempty
                  , changeAddress
                  , addresses
                  , collateralUTxOs
                  }

              post' runtime.serverURL transactionsEndpoint req
                >>= case _ of
                  Right ({ resource: PostTransactionsResponse postTransactionsResponse, links: { transaction: transactionEndpoint } }) -> do
                    traceM postTransactionsResponse
                    let
                      { tx } = postTransactionsResponse
                      TextEnvelope { cborHex: txCborHex } = tx
                    Wallet.signTx walletApi txCborHex true >>= case _ of
                      Right witnessSet -> do
                        submit witnessSet runtime.serverURL transactionEndpoint >>= case _ of
                          Right _ -> do
                            traceM "Successfully submitted the transaction"
                            liftEffect $ msgHubProps.add $ Success $ DOOM.text $ "Successfully submitted a transaction"
                          -- liftEffect $ onSuccess contractEndpoint
                          Left err -> do
                            traceM "Error while submitting the transaction"
                            liftEffect $ msgHubProps.add $ Error $ DOOM.text $ "Error while submitting the transaction"
                            traceM err

                      Left err -> do
                        traceM err
                        pure unit

                    pure unit
                  Left _ -> do
                    traceM token
                    -- traceM $ BigInt.toString value
                    traceM "error"
                    pure unit

              pure unit
            _ -> do
              -- Note: this happens, when the contract is in status `Unsigned`
              pure unit

        updateState _ { newInput = Nothing }

    pure $
      DOOM.div_
        [ case state.newContract, state.newInput, connectedWallet of
            true, _, Just cw -> createContractComponent
              { connectedWallet: cw
              , onDismiss: updateState _ { newContract = false }
              , onSuccess: \_ -> do
                  msgHubProps.add $ Success $ DOOM.text $ fold
                    [ "Successfully submitted the contract. Contract transaction awaits to be included in the blockchain."
                    , "Contract status should change to 'Confirmed' at that point."
                    ]
                  updateState _ { newContract = false }
              , inModal: true
              }
            _, Just input, Just cw -> modal $
                { body:
                    DOM.form {} $
                      [ DOM.div { className: "form-group" }
                          [ DOM.label
                              { className: "form-control-label" }
                              "Amount"
                          , R.input
                              { className: "form-control"
                              , type: "text"
                              , value: ""
                              }
                          ]
                      , DOM.div { className: "form-group" }
                          [ DOM.label
                              { className: "form-control-label" }
                              "Token"
                          , R.input
                              { className: "form-control"
                              , type: "text"
                              , value: ""
                              }
                          ]
                      , DOM.div { className: "form-group" }
                          [ DOM.label
                              { className: "form-control-label" }
                              "Party"
                          , R.input
                              { className: "form-control"
                              , type: "text"
                              , value: ""
                              }
                          ]
                      ]
                , onDismiss: updateState _ { newInput = Nothing }
                , title: text "Apply inputs"
                , footer: DOOM.fragment
                    [ link
                        { label: DOOM.text "Cancel"
                        , onClick: updateState _ { newInput = Nothing }
                        , showBorders: true
                        }
                    , DOM.button
                        { className: "btn btn-primary"
                        , onClick: onApplyInputs input { value: BigInt.fromInt 1, token: V1.Token "" "", party: V1.Address "" } cw
                        }
                        [ R.text "Submit" ]
                    ]
                }
            _, _, _ -> mempty
        , DOM.div { className: "row justify-content-end" } $ Array.singleton $ do
            let
              disabled = isNothing connectedWallet
              addContractLink = linkWithIcon
                { icon: Icons.fileEarmarkPlus
                , label: DOOM.text "Add contract"
                , disabled
                , onClick: onAddContractClick
                }
            DOM.div { className: "col-3 text-end" } $ Array.singleton $
              if disabled then do
                let
                  tooltipJSX = tooltip {} (DOOM.text "Connect to a wallet to add a contract")
                overlayTrigger
                  { overlay: tooltipJSX
                  , placement: OverlayTrigger.placement.bottom
                  }
                  -- Disabled button doesn't trigger the hook,
                  -- so we wrap it in a `span`
                  (DOOM.span_ [ addContractLink ])
              else
                addContractLink
        , DOM.div { className: "row" } $ Array.singleton $ case state.metadata of
            Just (metadata) -> modal $
              { body: text $ maybe "Empty Metadata" (show <<< _.contractTerms <<< unwrap) $ M.decodeMetadata metadata -- TODO: encode contractTerms as JSON
              , onDismiss: updateState _ { metadata = Nothing }
              , title: text "Contract Terms"
              , footer: text ""
              }
            Nothing -> mempty
        , table { striped: Table.striped.boolean true, hover: true }
            [ DOM.thead {} do
                let
                  orderingTh = Table.orderingHeader ordering updateOrdering
                  th label = DOM.th { className: "text-center text-muted" } [ label ]
                [ DOM.tr {}
                    [ do
                        let
                          label = DOOM.fragment [ DOOM.text "Created" ] --, DOOM.br {},  DOOM.text "(Block number)"]
                        orderingTh label OrderByCreationDate
                    , th $ DOOM.text "Contract Id"
                    , th $ DOOM.text "Status"
                    , th $ DOOM.text "Inputs"
                    ]
                ]
            , DOM.tbody {} $ map
                ( \ci@(ContractInfo { _runtime, endpoints, marloweInfo }) ->
                    let
                      ContractHeader { contractId, status } = _runtime.contractHeader
                      tdCentered = DOM.td { className: "text-center" }
                    in
                      DOM.tr {}
                        [ tdCentered [ text $ foldMap show $ map (un Runtime.BlockNumber <<< _.blockNo <<< un Runtime.BlockHeader) $ ContractInfo.createdAt ci ]
                        , tdCentered [ DOM.a
                           { className: "btn btn-link text-decoration-none text-reset text-decoration-underline-hover"
                           , target: "_blank"
                           , href: "http://marlowe.palas87.es:8002/contractView?tab=info&contractId=" <> (txOutRefToUrlEncodedString contractId)
                           }
                           [ text $ txOutRefToString contractId ]
                          ]
                        , DOM.td { className: "text-center" } $ do
                            let
                              tooltipJSX = tooltip {} (DOOM.text $ txOutRefToString contractId)
                            overlayTrigger
                              { overlay: tooltipJSX
                              , placement: OverlayTrigger.placement.bottom
                              } $ DOM.span {} [ show status ]
                        , tdCentered
                            [ case endpoints.transactions of
                                Just transactionsEndpoint -> linkWithIcon { icon: Icons.listOl, label: DOOM.text "Apply", onClick: updateState _ { newInput = Just { transactionsEndpoint, marloweInfo} } }
                                _ -> mempty
                            ]
                        ]
                )
                contractList'
            ]
        ]
